/* xnoise-media-browser-model.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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


using Gtk;

public class Xnoise.MediaBrowserModel : Gtk.TreeStore, Gtk.TreeModel {

	public enum Column {
		ICON = 0,
		VIS_TEXT,
		DB_ID,
		MEDIATYPE,
		COLL_TYPE,
		DRAW_SEPTR,
		VISIBLE,
		N_COLUMNS
	}

	public enum CollectionType {
		UNKNOWN = 0,
		HIERARCHICAL = 1,
		LISTED = 2
	}

	private GLib.Type[] col_types = new GLib.Type[] {
		typeof(Gdk.Pixbuf), //ICON
		typeof(string),     //VIS_TEXT
		typeof(int),        //DB_ID
		typeof(int),        //MEDIATYPE
		typeof(int),        //COLL_TYPE
		typeof(int),        //DRAW SEPARATOR
		typeof(bool)        //VISIBLE
	};

	public string searchtext = "";
	private IconTheme theme = null;
	private Gdk.Pixbuf artist_pixb;
	private Gdk.Pixbuf album_pixb;
	private Gdk.Pixbuf title_pixb;
	private Gdk.Pixbuf video_pixb;
	private Gdk.Pixbuf videos_pixb;
	private Gdk.Pixbuf radios_pixb;

	construct {
		theme = IconTheme.get_default();
		theme.changed.connect(update_pixbufs);
		set_pixbufs();
		set_column_types(col_types);
	}
	
	private void update_pixbufs() {
		this.set_pixbufs();
		if(Main.instance.main_window != null)
			if(Main.instance.main_window.mediaBr != null) {
				this.ref();
				Main.instance.main_window.mediaBr.change_model_data();
				this.unref();
			}
	}
	
	public int get_max_icon_width() {
		return artist_pixb.width + title_pixb.width + album_pixb.width;
	}
		

	public void filter() {
		this.foreach(filterfunc);
	}

	private bool filterfunc(Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
//		TreePath p = this.get_path(iter);
		switch(path.get_depth()) {
			case 1: //ARTIST
				string artist = null;
				this.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref artist);
				if(artist != null && artist.down().str(searchtext) != null) {
					this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
					return false;
				}
				TreeIter iterChild;
				for(int i = 0; i < this.iter_n_children(iter); i++) {
					this.iter_nth_child(out iterChild, iter, i);
					string album = null;
					this.get(iterChild, MediaBrowserModel.Column.VIS_TEXT, ref album);
					if(album != null && album.down().str(searchtext) != null) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
					TreeIter iterChildChild;
					for(int j = 0; j < this.iter_n_children(iterChild); j++) {
						this.iter_nth_child(out iterChildChild, iterChild, j);
						string title = null;
						this.get(iterChildChild, MediaBrowserModel.Column.VIS_TEXT, ref title);
						if(title != null && title.down().str(searchtext) != null) {
							this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
							return false;
						}
					}
				}
				this.set(iter, MediaBrowserModel.Column.VISIBLE, false);
				return false;
			case 2: //ALBUM
				string album = null;
				this.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref album);
				if(album != null && album.down().str(searchtext) != null) {
					this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
					return false;
				}
				TreeIter iterChild;
				for(int i = 0; i < this.iter_n_children(iter); i++) {
					this.iter_nth_child(out iterChild, iter, i);
					string title = null;
					this.get(iterChild, MediaBrowserModel.Column.VIS_TEXT, ref title);
					if(title != null && title.down().str(searchtext) != null) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
				}
				TreeIter iter_parent;
				string artist = null;
				if(this.iter_parent(out iter_parent, iter)) {
					this.get(iter_parent, MediaBrowserModel.Column.VIS_TEXT, ref artist);
					if(artist != null && artist.down().str(searchtext) != null) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
				}
				this.set(iter, MediaBrowserModel.Column.VISIBLE, false);
				return false;
			case 3: //TITLE
				string title = null;
				this.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref title);
				if(title != null && title.down().str(searchtext) != null) {
					this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
					return false;
				}
				TreeIter iter_parent;
				string album = null;
				if(this.iter_parent(out iter_parent, iter)) {
					this.get(iter_parent, MediaBrowserModel.Column.VIS_TEXT, ref album);
					if(album != null && album.down().str(searchtext) != null) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
					TreeIter iter_parent_parent;
					string artist = null;
					if(this.iter_parent(out iter_parent_parent, iter_parent)) {
						this.get(iter_parent_parent, MediaBrowserModel.Column.VIS_TEXT, ref artist);
						if(artist != null && artist.down().str(searchtext) != null) {
							this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
							return false;
						}
					}
				}
				this.set(iter, MediaBrowserModel.Column.VISIBLE, false);
				return false;
			default:
				this.set(iter, MediaBrowserModel.Column.VISIBLE, false);
				return false;
		}
	}

	private void set_pixbufs() {
		try {
			
			Gtk.Invisible w = new Gtk.Invisible();
			
			if(theme.has_icon("system-users")) artist_pixb = theme.load_icon("system-users", 0, 0);
			else if(theme.has_icon("stock_person")) artist_pixb = theme.load_icon("stock_person", 0, 0);
			else artist_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "guitar.png");
			
			album_pixb = w.render_icon(Gtk.STOCK_CDROM, IconSize.BUTTON, null);
			
			if(theme.has_icon("audio-x-generic")) title_pixb = theme.load_icon("audio-x-generic", 0, 0);
			else title_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "guitar.png");
			
			if(theme.has_icon("video-x-generic")) videos_pixb = theme.load_icon("video-x-generic", 0, 0);
			else videos_pixb = w.render_icon(Gtk.STOCK_MEDIA_RECORD, IconSize.BUTTON, null);
			
			radios_pixb  = w.render_icon(Gtk.STOCK_CONNECT, IconSize.BUTTON, null);
			video_pixb  = w.render_icon(Gtk.STOCK_FILE, IconSize.BUTTON, null);
		}
		catch (GLib.Error e) {
			print("Error: %s\n",e.message);
		}
	}

	private void prepend_separator() {
		TreeIter iter;
		this.prepend(out iter, null);
		this.set(iter, Column.DRAW_SEPTR, 1, -1);
	}

//	public void insert_sorted(TrackData td) {
//		
//		if(td == null)
//			return;
//		
//		TreeIter artist_iter, album_iter;
//		string test = null;
//		if(!get_iter_for_artist(ref artist, out artist_iter)) {
//			
//		}
//		if(!get_iter_for_album(ref album, ref artist_iter, out album_iter)) {
//			
//		}
//		
//	}
	
	private bool get_iter_for_artist(ref string artist, out TreeIter artist_iter) {
		string text = null;
		for(int i = 0; i < this.iter_n_children(null); i++) {
			this.iter_nth_child(out artist_iter, null, i);
			this.get(artist_iter, Column.VIS_TEXT, ref text);
			if(text == artist)
				return true;
		}
		return false;
	}
	
	private bool get_iter_for_album(ref string album, ref TreeIter artist_iter, out TreeIter album_iter) {
		string text = null;
		for(int i = 0; i < this.iter_n_children(artist_iter); i++) {
			this.iter_nth_child(out album_iter, null, i);
			this.get(album_iter, Column.VIS_TEXT, ref text);
			if(text == album)
				return true;
		}
		return false;
	}
	
	public bool populate_model() {
		Worker.Job job;
		job = new Worker.Job(1, Worker.ExecutionType.SYNC, null, this.handle_listed_data);
		worker.push_job(job);
		
		job = new Worker.Job(1, Worker.ExecutionType.ASYNC, this.handle_hierarchical_data, null);
		worker.push_job(job);
		
		return false;
	}
	
//	private DbBrowser dbb = null;
//	private DbBrowser import_listed_dbb = null;
	
	private void handle_listed_data(Worker.Job job) {
		var stream_job = new Worker.Job(1, Worker.ExecutionType.SYNC, null, this.handle_streams);
		worker.push_job(stream_job);
		
		var video_job = new Worker.Job(1, Worker.ExecutionType.SYNC, null, this.handle_videos);
		worker.push_job(video_job);
	}
	
	private void handle_streams(Worker.Job job) {
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}		
		job.media_dat = dbb.get_stream_data(ref searchtext);
		
		if(job.media_dat.length == 0)
			return;
		
		Idle.add( () => {
			TreeIter iter_radios, iter_singleradios;
			this.prepend(out iter_radios, null);
			this.set(iter_radios,
			         Column.ICON, radios_pixb,
			         Column.VIS_TEXT, "Streams",
			         Column.COLL_TYPE, CollectionType.LISTED,
			         Column.DRAW_SEPTR, 0,
			         Column.VISIBLE, true
			         );
			foreach(unowned MediaData tmi in job.media_dat) {
				this.prepend(out iter_singleradios, iter_radios);
				this.set(iter_singleradios,
				         Column.ICON,        radios_pixb,
				         Column.VIS_TEXT,    tmi.name,
				         Column.DB_ID,       tmi.id,
				         Column.MEDIATYPE ,  (int)MediaType.STREAM,
				         Column.COLL_TYPE,   CollectionType.LISTED,
				         Column.DRAW_SEPTR,  0,
				         Column.VISIBLE, true
				         );
			}
			return false;
		});
	}
	
	private void handle_videos(Worker.Job job) {
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}		
		job.media_dat = dbb.get_video_data(ref searchtext);
		
		if(job.media_dat.length == 0)
			return;
		
		Idle.add( () => {
			TreeIter iter_videos, iter_singlevideo;
			this.prepend(out iter_videos, null);
			this.set(iter_videos,
				     Column.ICON, videos_pixb,
				     Column.VIS_TEXT, "Videos",
				     Column.COLL_TYPE, CollectionType.LISTED,
				     Column.DRAW_SEPTR, 0,
			         Column.VISIBLE, true
				     );
			foreach(unowned MediaData tmi in job.media_dat) {
				this.prepend(out iter_singlevideo, iter_videos);
				this.set(iter_singlevideo,
					     Column.ICON, video_pixb,
					     Column.VIS_TEXT, tmi.name,
					     Column.DB_ID, tmi.id,
					     Column.MEDIATYPE , (int) MediaType.VIDEO,
					     Column.COLL_TYPE, CollectionType.LISTED,
					     Column.DRAW_SEPTR, 0,
					     Column.VISIBLE, true
					     );
			}
			return false;
		});
	}

	//repeat until returns false
	private bool handle_hierarchical_data(Worker.Job job) {
		DbBrowser dbb = null;
		//TODO: Use Cancellable
		if(dbb == null) {
			try {
				dbb = new DbBrowser();
			}
			catch(Error e) {
				print("%s\n", e.message);
				dbb = null;
				return false;
			}
			if(dbb == null) {
				print("unable to get DB handle\n");
				return false;
			}
		}
		// use job.big_counter[0] for artist count
		// use job.big_counter[1] for offset
		
		if(job.big_counter[0] == 0) {
			if(dbb == null) {
				try {
					dbb = new DbBrowser();
				}
				catch(Error e) {
					print("%s\n", e.message);
					dbb = null;
					return false;
				}
				if(dbb == null) {
					print("unable to get DB handle\n");
					return false;
				}
			}
			job.big_counter[0] = dbb.count_artists_with_search(ref searchtext);
		}
		
		if(job.big_counter[0] == 0) {
			dbb = null;
			return false;
		}
		
		if((job.big_counter[1] + ARTIST_FOR_ONE_JOB) > job.big_counter[0]) {
			// last round
			//print("done import\n");
			dbb = null;
			return false;
		}
		var artist_job = new Worker.Job(1, Worker.ExecutionType.SYNC, null, this.handle_artists);
		
		artist_job.big_counter[1] = job.big_counter[1]; //current offset
		
		worker.push_job(artist_job);
		
		// increment offset
		job.big_counter[1] = job.big_counter[1] + ARTIST_FOR_ONE_JOB;
		
		return true;
	}
	
	private const int ARTIST_FOR_ONE_JOB = 12;
	private void handle_artists(Worker.Job job) {
		string[] artistArray;
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
//		Timer t = new Timer();
//		t.reset();
//		ulong microseconds;
//		t.start();
		artistArray = dbb.get_some_artists_2(ARTIST_FOR_ONE_JOB, job.big_counter[1]);
//		t.stop();
//		double buf = t.elapsed(out microseconds);
//		print("\nelapsed get some artists 2:: %lf ; %u\n", buf, (uint)microseconds);
		
		job.big_counter[1] += artistArray.length;
		
		job.set_arg("artistArray", artistArray);
		Idle.add( () => {
			TreeIter iter_artist;
			foreach(string artist in (string[])job.get_arg("artistArray")) { 	              //ARTISTS
				this.append(out iter_artist, null);
				this.set(iter_artist,
				         Column.ICON, artist_pixb,
				         Column.VIS_TEXT, artist,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, true
				         );
				
				Gtk.TreePath p = this.get_path(iter_artist);
				TreeRowReference treerowref = new TreeRowReference(this, p);
				var job_album = new Worker.Job(1, Worker.ExecutionType.SYNC, null, this.handle_album);
				job_album.set_arg("treerowref", treerowref);
				job_album.set_arg("artist", artist);
				worker.push_job(job_album);
			}
			return false;
		});
		return;
	}
//	private void handle_artists(Worker.Job job) {
//		string[] artistArray;
//		DbBrowser dbb = null;
//		try {
//			dbb = new DbBrowser();
//		}
//		catch(Error e) {
//			print("%s\n", e.message);
//			return;
//		}
//		artistArray = dbb.get_some_artists(ref searchtext, ARTIST_FOR_ONE_JOB, job.big_counter[1]);
//		job.big_counter[1] += artistArray.length;
//		
//		job.set_arg("artistArray", artistArray);
//		Idle.add( () => {
//			TreeIter iter_artist;
//			foreach(string artist in (string[])job.get_arg("artistArray")) { 	              //ARTISTS
//				this.append(out iter_artist, null);
//				this.set(iter_artist,
//				         Column.ICON, artist_pixb,
//				         Column.VIS_TEXT, artist,
//				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
//				         Column.DRAW_SEPTR, 0);
//				
//				Gtk.TreePath p = this.get_path(iter_artist);
//				TreeRowReference treerowref = new TreeRowReference(this, p);
//				var job_album = new Worker.Job(1, Worker.ExecutionType.SYNC, null, this.handle_album);
//				job_album.set_arg("treerowref", treerowref);
//				job_album.set_arg("artist", artist);
//				worker.push_job(job_album);
//			}
//			return false;
//		});
//		return;
//	}
	
	private void handle_album(Worker.Job job) {
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}		
		string artist = (string)job.get_arg("artist");
//		Timer t = new Timer();
//		t.reset();
//		ulong microseconds;
//		t.start();
		string[] albumArray = dbb.get_albums_2(artist);
//		t.stop();
//		double buf = t.elapsed(out microseconds);
//		print("\nelapsed get albums 2:: %lf ; %u\n", buf, (uint)microseconds);
		
		job.set_arg("albumArray", albumArray);
		Idle.add( () => {
				TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
				TreePath p = row_ref.get_path();
				TreeIter iter_artist, iter_album;
				this.get_iter(out iter_artist, p);
				foreach(string album in (string[])job.get_arg("albumArray")) { 			    //ALBUMS
					this.prepend(out iter_album, iter_artist);
					this.set(iter_album,
					         Column.ICON, album_pixb,
					         Column.VIS_TEXT, album,
					         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
					         Column.DRAW_SEPTR, 0,
					         Column.VISIBLE, true
					         );
					Gtk.TreePath p1 = this.get_path(iter_album);
					TreeRowReference treerowref = new TreeRowReference(this, p1);
					var job_title = new Worker.Job(1, Worker.ExecutionType.SYNC, null, this.handle_titles);
					job_title.set_arg("treerowref", treerowref);
					job_title.set_arg("artist", artist);
					job_title.set_arg("album", album);
					worker.push_job(job_title);
				}
			return false;
		});
	}

	private void handle_titles(Worker.Job job) {
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
		string ar, al;
		ar = (string)job.get_arg("artist");
		al = (string)job.get_arg("album");
//		Timer t = new Timer();
//		t.reset();
//		ulong microseconds;
//		t.start();
		MediaData[] tmis = dbb.get_titles_with_mediatypes_and_ids_2(ar, al);
//		t.stop();
//		double buf = t.elapsed(out microseconds);
//		print("\nelapsed get albums 2:: %lf ; %u\n", buf, (uint)microseconds);
		
		job.media_dat = tmis;
		
		Idle.add( () => {
			TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
			TreePath p = row_ref.get_path();
			TreeIter iter_title, iter_album;
			this.get_iter(out iter_album, p);
			foreach(unowned MediaData tmi in job.media_dat) {	         //TITLES WITH MEDIATYPES
				this.prepend(out iter_title, iter_album);
				if(tmi.mediatype == MediaType.AUDIO) {
					this.set(iter_title,
						     Column.ICON, title_pixb,
						     Column.VIS_TEXT, tmi.name,
						     Column.DB_ID, tmi.id,
						     Column.MEDIATYPE , tmi.mediatype,
						     Column.COLL_TYPE, CollectionType.HIERARCHICAL,
						     Column.DRAW_SEPTR, 0,
					         Column.VISIBLE, true
						     );
				}
				else {
					this.set(iter_title,
						     Column.ICON, video_pixb,
						     Column.VIS_TEXT, tmi.name,
						     Column.DB_ID, tmi.id,
						     Column.MEDIATYPE, tmi.mediatype,
						     Column.COLL_TYPE, CollectionType.HIERARCHICAL,
						     Column.DRAW_SEPTR, 0,
						     Column.VISIBLE, true
						     );
				}
			}
			return false;
		});
	}

	public TrackData[] get_trackdata_listed(Gtk.TreePath treepath) {
		//this is only used for path.get_depth() == 2 !
		int dbid = -1;
		MediaType mtype = MediaType.UNKNOWN;
		TreeIter iter;
		TrackData[] tdata = {};
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return tdata;
		}		
		this.get_iter(out iter, treepath);
		this.get(iter,
		         Column.DB_ID, ref dbid,
		         Column.MEDIATYPE, ref mtype
		         );
		if(dbid!=-1) {
			TrackData td;
			switch(mtype) {
				case MediaType.VIDEO: {
					if(dbb.get_trackdata_for_id(dbid, out td)) tdata += td;
					break;
				}
				case MediaType.STREAM: {
					if(dbb.get_stream_td_for_id(dbid, out td)) tdata += td;
					break;
				}
				default:
					break;
			}
		}
		return tdata;
	}

	public TrackData[] get_trackdata_hierarchical(Gtk.TreePath treepath) {
		TreeIter iter, iterChild;
		int dbid = -1;
		TrackData[] tdata = {};
		if(treepath.get_depth() ==1)
			return tdata;
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return tdata;
		}
		switch(treepath.get_depth()) {
			case 1: //ARTIST (this case is currently not used)
				break;
			case 2: //ALBUM
				this.get_iter(out iter, treepath);

				for(int i = 0; i < this.iter_n_children(iter); i++) {
					dbid = -1;
					this.iter_nth_child(out iterChild, iter, i);
					this.get(iterChild, Column.DB_ID, ref dbid);
					if(dbid==-1)
						continue;
					TrackData td;
					if(dbb.get_trackdata_for_id(dbid, out td)) 
						tdata += td;
				}
				break;
			case 3: //TITLE
				dbid = -1;
				this.get_iter(out iter, treepath);
				this.get(iter, Column.DB_ID, ref dbid);
				if(dbid==-1) 
					break;
				TrackData td;
				if(dbb.get_trackdata_for_id(dbid, out td)) 
					tdata += td;
				break;
		}
		return tdata;
	}

	public TrackData[] get_trackdata_for_treepath(Gtk.TreePath treepath) {
		TreeIter iter;
		CollectionType br_ct = CollectionType.UNKNOWN;
		TrackData[] tdata = {};
		this.get_iter(out iter, treepath);
		this.get(iter, Column.COLL_TYPE, ref br_ct);
		if(br_ct == CollectionType.LISTED) {
			return get_trackdata_listed(treepath);
		}
		else if(br_ct == CollectionType.HIERARCHICAL) {
			return get_trackdata_hierarchical(treepath);
		}
		return tdata;
	}

	public int32[] build_id_list_for_iter(ref TreeIter iter) {
		TreeIter iterChild, iterChildChild;
		int32[] urilist = {};
		MediaType mtype = MediaType.UNKNOWN;
		int dbid = -1;
		//string uri;
		TreePath treepath;
		CollectionType br_ct = CollectionType.UNKNOWN;
		treepath = this.get_path(iter);
		bool visible = false;
		switch(treepath.get_depth()) {
			case 1:
			//this.get_iter(out iter, treepath);
				this.get(iter, Column.COLL_TYPE, ref br_ct);
				if(br_ct == CollectionType.LISTED) {
					dbid = -1;
					for(int i = 0; i < this.iter_n_children(iter); i++) {
						dbid = -1;
						this.iter_nth_child(out iterChild, iter, i);
						this.get(iterChild,
						         Column.DB_ID, ref dbid,
						         Column.VISIBLE, ref visible
//						         Column.MEDIATYPE, ref mtype
						         );
						if(visible)
							urilist += dbid;
//						if(dbid==-1) break;
//						switch(mtype) {
//							case MediaType.VIDEO: {
//								if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
//								break;
//							}
//							case MediaType.STREAM : {
//								if(dbb.get_stream_for_id(dbid, out uri)) urilist += uri;
//								break;
//							}
//							default:
//								break;
//						}
					}
				}
				else if(br_ct == CollectionType.HIERARCHICAL) {
					for(int i = 0; i < this.iter_n_children(iter); i++) {
						this.iter_nth_child(out iterChild, iter, i);
						this.get(iterChild,
						         Column.VISIBLE, ref visible
						         );
						if(!visible)
							continue;
						for(int j = 0; j<this.iter_n_children(iterChild); j++) {
							dbid = -1;
							this.iter_nth_child(out iterChildChild, iterChild, j);
							this.get(iterChildChild, 
							         Column.DB_ID, ref dbid,
							         Column.VISIBLE, ref visible
							         );
							if(dbid != -1 && visible)
								urilist += dbid;
						}
					}
				}
				break;
			case 2:
//				this.get_iter(out iter, treepath);
				this.get(iter, Column.COLL_TYPE, ref br_ct);
				if(br_ct == CollectionType.LISTED) {
					dbid = -1;
					mtype = MediaType.UNKNOWN;
					this.get(iter,
					         Column.DB_ID, ref dbid,
					         Column.VISIBLE, ref visible
//					         Column.MEDIATYPE, ref mtype
					         );
					if(dbid==-1) break;
					
					if(visible)
						urilist += dbid;
					
//						switch(mtype) {
//						case MediaType.VIDEO: {
//							//print("is VIDEO\n");
//							if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
//							break;
//						}
//						case MediaType.STREAM : {
//							//print("is STREAM\n");
//							if(dbb.get_stream_for_id(dbid, out uri)) urilist += uri;
//							break;
//						}
//						default:
//							break;
//					}
				}
				else if(br_ct == CollectionType.HIERARCHICAL) {

					for(int i = 0; i < this.iter_n_children(iter); i++) {
						dbid = -1;
						this.iter_nth_child(out iterChild, iter, i);
						this.get(iterChild, Column.DB_ID, ref dbid, Column.VISIBLE, ref visible);
							if(dbid != -1 && visible)
								urilist += dbid;
					}
				}
				break;
			case 3: //TITLE
				dbid = -1;
				this.get(iter, Column.DB_ID, ref dbid);
				if(dbid==-1) break;
				if(dbid != -1)
					urilist += dbid;
				break;
		}
		return urilist;
	}

	public string[] build_uri_list_for_treepath(Gtk.TreePath treepath, ref DbBrowser dbb) {
		TreeIter iter, iterChild, iterChildChild;
		string[] urilist = {};
		MediaType mtype = MediaType.UNKNOWN;
		int dbid = -1;
		string uri;
		CollectionType br_ct = CollectionType.UNKNOWN;

		switch(treepath.get_depth()) {
			case 1:
				this.get_iter(out iter, treepath);

				this.get(iter, Column.COLL_TYPE, ref br_ct);
				if(br_ct == CollectionType.LISTED) {
					dbid = -1;
					for(int i = 0; i < this.iter_n_children(iter); i++) {
						dbid = -1;
						this.iter_nth_child(out iterChild, iter, i);
						this.get(iterChild,
						         Column.DB_ID, ref dbid,
						         Column.MEDIATYPE, ref mtype
						         );
						if(dbid==-1) break;
						switch(mtype) {
							case MediaType.VIDEO: {
								if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
								break;
							}
							case MediaType.STREAM : {
								if(dbb.get_stream_for_id(dbid, out uri)) urilist += uri;
								break;
							}
							default:
								break;
						}
					}
				}
				else if(br_ct == CollectionType.HIERARCHICAL) {
					for(int i = 0; i < this.iter_n_children(iter); i++) {
						this.iter_nth_child(out iterChild, iter, i);
						for(int j = 0; j<this.iter_n_children(iterChild); j++) {
							dbid = -1;
							this.iter_nth_child(out iterChildChild, iterChild, j);
							this.get(iterChildChild, Column.DB_ID, ref dbid);
							if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
						}
					}
				}
				break;
			case 2:
				this.get_iter(out iter, treepath);
				this.get(iter, Column.COLL_TYPE, ref br_ct);
				if(br_ct == CollectionType.LISTED) {
					dbid = -1;
					mtype = MediaType.UNKNOWN;
					this.get(iter,
					         Column.DB_ID, ref dbid,
					         Column.MEDIATYPE, ref mtype
					         );
					if(dbid==-1) break;
						switch(mtype) {
						case MediaType.VIDEO: {
							//print("is VIDEO\n");
							if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
							break;
						}
						case MediaType.STREAM : {
							//print("is STREAM\n");
							if(dbb.get_stream_for_id(dbid, out uri)) urilist += uri;
							break;
						}
						default:
							break;
					}
				}
				else if(br_ct == CollectionType.HIERARCHICAL) {

					for(int i = 0; i < this.iter_n_children(iter); i++) {
						dbid = -1;
						this.iter_nth_child(out iterChild, iter, i);
						this.get(iterChild, Column.DB_ID, ref dbid);
						if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
					}
				}
				break;
			case 3: //TITLE
				dbid = -1;
				this.get_iter(out iter, treepath);
				this.get(iter, Column.DB_ID, ref dbid);
				if(dbid==-1) break;
				if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
				break;
		}
		return urilist;
	}
}
