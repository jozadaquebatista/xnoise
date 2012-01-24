/* xnoise-database-lyrics.vala
 *
 * Copyright (C) 2011  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 * 	Jörn Magens
 */

using Sqlite;
using Xnoise;
using Xnoise.Services;
using Xnoise.PluginModule;


public class Xnoise.DatabaseLyricsPlugin : GLib.Object, IPlugin, ILyricsProvider {
	private unowned Container _owner;
	private DatabaseLyricsWriter lyrics_writer;
	
	public unowned Main xn { get; set; }

	public Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}

	public string name {
		get {
			return DATABASELYRICS;
		}
	}
	
	public string provider_name {
		get {
			return DATABASELYRICS;
		}
	}
	
	public int priority { get; set; default = 1; }
	
	public bool init() {
		priority = -1; // highest prio
		lyrics_writer = new DatabaseLyricsWriter(main_window.lyricsView.get_loader());
		if(lyrics_writer != null)
			return true;
		return false;
	}

	public void uninit() {
		lyrics_writer = null;
		main_window.lyricsView.lyrics_provider_unregister(this); // for lyricsloader
	}
	
	~DatabaseLyricsPlugin() {
		//print("dtor DatabaseLyricsPlugin\n");
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public Xnoise.ILyrics* from_tags(LyricsLoader loader, string artist, string title, LyricsFetchedCallback cb) {
		return (ILyrics*)new DatabaseLyrics(loader, _owner, artist, title, cb);
	}
}


// subscribe to signals and write lyrics to local db
private class Xnoise.DatabaseLyricsWriter : GLib.Object {
	
	private Cancellable cancellable = new Cancellable();
	
	private static const string STMT_FIND_TABLE =
		"SELECT name FROM sqlite_master WHERE type='table';";
	private static const string INSERT_LYRICS =
		"INSERT INTO lyrics (artist, title, provider, txt, credits, identifier) VALUES (?,?,?,?,?,?);";
	private static const string STMT_CHECK_ENTRY_EXISTS =
		"SELECT identifier FROM lyrics WHERE artist = ? AND title = ? AND provider = ?";
	
	private unowned LyricsLoader loader;
	
	private string artist;
	private string title;
	private string credits;
	private string identifier;
	private string txt;
	private string provider;
	
	// all db writing actions on lyrics
	public DatabaseLyricsWriter(LyricsLoader _loader) {
		this.loader = _loader;
		check_table();
		loader.sign_fetched.connect( (a,t,c,i,tx,p) => {
			if(p == DATABASELYRICS) // already buffered in database
				return;
			if(tx == null || tx == EMPTYSTRING || tx.strip() == "no lyrics found...")
				return;
			artist = a;
			title = t;
			credits = c;
			identifier = i;
			txt = tx;
			provider = p;
			
			add_lyrics_entry();
		});
	}
	
	~DatabaseLyricsWriter() {
		//print("dtor DatabaseLyricsWriter\n");
	}
	
	private void check_table() {
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE, this.check_table_cb);
		job.cancellable = this.cancellable;
		db_worker.push_job(job);
	}
	
	private void add_lyrics_entry() {
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE, this.add_lyrics_entry_cb);
		job.cancellable = this.cancellable;
		db_worker.push_job(job);
	}
	
	private bool check_table_cb(Worker.Job job) {
		db_writer.do_callback_transaction(create_table_dbcb);
		return false;
	}
	
	private bool add_lyrics_entry_cb(Worker.Job job) {
		db_writer.do_callback_transaction(write_txt_dbcb);
		return false;
	}
	
	private void create_table_dbcb(Sqlite.Database db) {
		Statement stmt;
		bool db_table_exists = false;
		
		if(!cancellable.is_cancelled()) {
			
			db.prepare_v2(STMT_FIND_TABLE, -1, out stmt);
			stmt.reset();
			while(stmt.step() == Sqlite.ROW) {
				if(stmt.column_text(0) == "lyrics") {
					db_table_exists = true;
					break;
				}
			}
			if(!db_table_exists) {
				string errormsg;
				if(db.exec("CREATE TABLE lyrics(artist text, title text, provider text, txt text, credits text, identifier text);", null, out errormsg)!= Sqlite.OK) {
					stderr.printf("exec_stmnt_string error: %s", errormsg);
				}
			}
		}
	}

	private void write_txt_dbcb(Sqlite.Database db) {
		Statement stmt;
		//TODO check for entry existance, first
		if(!cancellable.is_cancelled()) {
			db.prepare_v2(STMT_CHECK_ENTRY_EXISTS, -1, out stmt);
			stmt.reset();
			if(stmt.bind_text(1, prepare_for_comparison(artist))     != Sqlite.OK ||
			   stmt.bind_text(2, prepare_for_comparison(title))      != Sqlite.OK ||
			   stmt.bind_text(3, provider)                           != Sqlite.OK) {
				print("Database lyrics error %d: %s \n\n", db.errcode(), db.errmsg());
				return;
			}
			if(stmt.step() == Sqlite.ROW) {
				return; // Entry is already in table
			}
			
			db.prepare_v2(INSERT_LYRICS, -1, out stmt);
			stmt.reset();
			if(stmt.bind_text(1, prepare_for_comparison(artist))     != Sqlite.OK ||
			   stmt.bind_text(2, prepare_for_comparison(title))      != Sqlite.OK ||
			   stmt.bind_text(3, provider)                           != Sqlite.OK ||
			   stmt.bind_text(4, txt)                                != Sqlite.OK ||
			   stmt.bind_text(5, credits)                            != Sqlite.OK ||
			   stmt.bind_text(6, identifier)                         != Sqlite.OK) {
				print("Database lyrics error %d: %s \n\n", db.errcode(), db.errmsg());
				return;
			}
			if(stmt.step() != Sqlite.DONE) {
				print("Database lyrics error %d: %s \n\n", db.errcode(), db.errmsg());
				return;
			}
		}
	}
}



private static const string DATABASELYRICS = "DatabaseLyrics";

// get lyrics from local database
public class Xnoise.DatabaseLyrics : GLib.Object, ILyrics {
	private string artist;
	private string title;
	private const int SECONDS_FOR_TIMEOUT = 2;
	private uint timeout;
	private unowned PluginModule.Container owner;
	private unowned LyricsLoader loader;
	private LyricsFetchedCallback cb = null;
	private Cancellable cancellable = new Cancellable();

	
	public DatabaseLyrics(LyricsLoader _loader, PluginModule.Container _owner, string artist, string title, LyricsFetchedCallback _cb) {
		this.artist = artist;
		this.title = title;
		this.owner = _owner;
		this.loader = _loader;
		this.cb = _cb;
		this.owner.sign_deactivated.connect( () => {
			destruct();
		});
		
		timeout = 0;
	}
	
	~DatabaseLyrics() {
		//print("remove DatabaseLyrics IL\n");
	}

	public uint get_timeout() {
		return timeout;
	}
	
	public string get_credits() {
		return EMPTYSTRING;
	}
	
	public string get_identifier() {
		return DATABASELYRICS;
	}
	
	protected bool timeout_elapsed() {
		if(MainContext.current_source().is_destroyed())
			return false;
			
		this.cancellable.cancel();
		
		Idle.add( () => {
			if(this.cb != null)
				this.cb(artist, title, get_credits(), get_identifier(), EMPTYSTRING, DATABASELYRICS);
			return false;
		});
		
		timeout = 0;
		Timeout.add_seconds(1, () => {
			destruct();
			return false;
		});
		return false;
	}
	
	private void find_lyrics() {
		
		timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
		
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE, this.get_lyrics_from_db);
		job.cancellable = this.cancellable;
		db_worker.push_job(job);
	}
	
	private void dbcb(Sqlite.Database db) {
		Statement stmt;
		if(!cancellable.is_cancelled()) {
			db.prepare_v2("SELECT txt, credits, identifier FROM lyrics WHERE LOWER(artist) = ? AND LOWER(title) = ?", -1, out stmt);
			
			stmt.reset();
			
			string txt = EMPTYSTRING;
			string cred = EMPTYSTRING;
			string ident = EMPTYSTRING;
			
			if((stmt.bind_text(1, "%s".printf(prepare_for_comparison(this.artist))) != Sqlite.OK)|
			   (stmt.bind_text(2, "%s".printf(prepare_for_comparison(this.title))) != Sqlite.OK)) {
				print("Error in database lyrics\n");;
			}
			if(stmt.step() == Sqlite.ROW) {
				txt = stmt.column_text(0);
				cred = stmt.column_text(1);
				ident = stmt.column_text(2);
				Idle.add( () => {
					if(this.cb != null)
						this.cb(artist, title, cred, ident, txt, DATABASELYRICS);
					this.destruct();
					return false;
				});
			}
			else {
				Idle.add( () => {
					if(this.cb != null)
						this.cb(artist, title, cred, ident, EMPTYSTRING, DATABASELYRICS);
					this.destruct();
					return false;
				});
			}
		}
		//lock(dbb) {
		//	dbb = null;
		//}
	}

	private bool get_lyrics_from_db(Worker.Job job) {
		db_browser.do_callback_transaction(dbcb);
		return false;
	}
}
