/* xnoise-media-browser-model.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
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
		DRAW_SEPTR,
		ITEM,
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
		typeof(int),        //DRAW SEPARATOR
		typeof(Xnoise.Item?)//ITEM
	};

	public string searchtext = "";
	private unowned IconTheme theme = null;
	private Gdk.Pixbuf artist_pixb;
	private Gdk.Pixbuf album_pixb;
	private Gdk.Pixbuf title_pixb;
	private Gdk.Pixbuf video_pixb;
	private Gdk.Pixbuf videos_pixb;
	private Gdk.Pixbuf radios_pixb;
	private Gdk.Pixbuf loading_pixb;
	private unowned Main xn;
	
	public bool populating_model { get; private set; default = false; }
	
	private uint refresh_timeout = 0;
	
	construct {
		xn = Main.instance;
		theme = IconTheme.get_default();
		theme.changed.connect(update_pixbufs);
		set_pixbufs();
		set_column_types(col_types);
		global.notify["image-path-small"].connect( () => {
			Timeout.add(100, () => {
				update_album_image();
				return false;
			});
		});
//		global.notify["media-import-in-progress"].connect( () => {
//			if(!global.media_import_in_progress) {
//				Idle.add( () => {
//					filter();
//					return false;
//				});
//			}
//		});
		db_writer.register_change_callback(database_change_cb);
	}
	
	// this function is running in db thread so use idle
	private void database_change_cb(DbWriter.ChangeType changetype, Item? item) {
		switch(changetype) {
			case DbWriter.ChangeType.ADD_ARTIST:
				//print("got new artist\n");
				if(item.db_id == -1){
					print("GOT -1\n");
					return;
				}
				Worker.Job job;
				job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.add_imported_artist_job);
				job.item = item;
				db_worker.push_job(job);
				break;
			default: break;
		}
	}
	
	private bool add_imported_artist_job(Worker.Job job) {
		int32 _id = job.item.db_id;
		job.item = db_browser.get_artistitem_by_artistid(ref searchtext, _id); // necessary because of search
		if(job.item.type == ItemType.UNKNOWN) // not matching searchtext
			return false;
		Idle.add( () => {
			if(populating_model) // don't try to put an artist to the model in case we are filling anyway
				return false;
			string text = null;
			TreeIter iter_search, artist_iter;
			if(this.iter_n_children(null) == 0) {
				this.append(out artist_iter, null);
				this.set(artist_iter,
					     Column.ICON, artist_pixb,
					     Column.VIS_TEXT, job.item.text,
					     Column.ITEM, job.item
					     );
				Item? loader_item = Item(ItemType.LOADER);
				this.append(out iter_search, artist_iter);
				this.set(iter_search,
					     Column.ICON, loading_pixb,
					     Column.VIS_TEXT, LOADING,
					     Column.ITEM, loader_item
					     );
				return false;
			}
			CollectionType ct = CollectionType.UNKNOWN;
			string itemtext_prep = job.item.text.down().strip();
			for(int i = 0; i < this.iter_n_children(null); i++) {
				this.iter_nth_child(out artist_iter, null, i);
				this.get(artist_iter, Column.VIS_TEXT, out text); //, Column.COLL_TYPE, out ct
//				if(ct != CollectionType.HIERARCHICAL)
//					continue;
				text = text != null ? text.down().strip() : "";
				if(strcmp(text, itemtext_prep) == 0) {
					//found artist
					return false;
				}
				if(strcmp(text, itemtext_prep) > 0) {
					TreeIter new_artist_iter;
					this.insert_before(out new_artist_iter, null, artist_iter);
					this.set(new_artist_iter,
						     Column.ICON, artist_pixb,
						     Column.VIS_TEXT, job.item.text,
//						     Column.COLL_TYPE, CollectionType.HIERARCHICAL,
						     //Column.DRAW_SEPTR, 0,
						     Column.ITEM, job.item
						     );
					artist_iter = new_artist_iter;
					Item? loader_item = Item(ItemType.LOADER);
					this.append(out iter_search, artist_iter);
					this.set(iter_search,
							 Column.ICON, loading_pixb,
							 Column.VIS_TEXT, LOADING,
//							 Column.COLL_TYPE, CollectionType.HIERARCHICAL,
							 //Column.DRAW_SEPTR, 0,
							 Column.ITEM, loader_item
							 );
					return false;
				}
			}
			this.append(out artist_iter, null);
			this.set(artist_iter,
				     Column.ICON, artist_pixb,
				     Column.VIS_TEXT, job.item.text,
				     Column.ITEM, job.item
				     );
			Item? loader_item = Item(ItemType.LOADER);
			this.append(out iter_search, artist_iter);
			this.set(iter_search,
				     Column.ICON, loading_pixb,
				     Column.VIS_TEXT, LOADING,
				     Column.ITEM, loader_item
				     );
			return false;
		});
		return false;
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
		

//	public void cancel_filling() {
//		cancel = true;
//	}
//	
//	private static bool cancel = false;
//	private static int progress_handler() {
//		if(cancel) {
//			cancel = false;
//			return 1;
//		}
//		return 0;
//	}
	
	public void filter() {
		//print("filter\n");
		this.clear();
		this.populate_model();
	}

	private void set_pixbufs() {
		try {
			
			Gtk.Invisible w = new Gtk.Invisible();
			
			radios_pixb  = w.render_icon(Gtk.Stock.CONNECT, IconSize.BUTTON, null);
			video_pixb  = w.render_icon(Gtk.Stock.FILE, IconSize.BUTTON, null);
			int iconheight = video_pixb.height;
			
			if(theme.has_icon("system-users")) 
				artist_pixb = theme.load_icon("system-users", iconheight, IconLookupFlags.FORCE_SIZE);
			else if(theme.has_icon("stock_person")) 
				artist_pixb = theme.load_icon("stock_person", iconheight, IconLookupFlags.FORCE_SIZE);
			else 
				artist_pixb = w.render_icon(Gtk.Stock.ORIENTATION_PORTRAIT, IconSize.BUTTON, null);
			
			album_pixb = w.render_icon(Gtk.Stock.CDROM, IconSize.BUTTON, null);
			
			if(theme.has_icon("audio-x-generic")) 
				title_pixb = theme.load_icon("audio-x-generic", iconheight, IconLookupFlags.FORCE_SIZE);
			else 
				title_pixb = w.render_icon(Gtk.Stock.OPEN, IconSize.BUTTON, null);
			
			if(theme.has_icon("video-x-generic")) 
				videos_pixb = theme.load_icon("video-x-generic", iconheight, IconLookupFlags.FORCE_SIZE);
			else 
				videos_pixb = w.render_icon(Gtk.Stock.MEDIA_RECORD, IconSize.BUTTON, null);
			
			loading_pixb = w.render_icon(Gtk.Stock.REFRESH , IconSize.BUTTON, null);
		}
		catch(GLib.Error e) {
			print("Error: %s\n",e.message);
		}
	}

	//	private void prepend_separator() {
	//		TreeIter iter;
	//		this.prepend(out iter, null);
	//		this.set(iter, Column.DRAW_SEPTR, 1, -1);
	//	}

	public void insert_video_sorted(TrackData[] tda) {
		string text = null;
		TreeIter iter_videos = TreeIter(), iter_singlevideos;
		CollectionType ct = CollectionType.UNKNOWN; 
		if(this.iter_n_children(null) == 0) {
			Item? item = Item(ItemType.COLLECTION_CONTAINER_VIDEO);
			this.prepend(out iter_videos, null);
			this.set(iter_videos,
			         Column.ICON, videos_pixb,
			         Column.VIS_TEXT, "Videos",
			         Column.ITEM, item
			         );
		}
		else {
			bool found = false;
			for(int i = 0; i < this.iter_n_children(null); i++) {
				this.iter_nth_child(out iter_videos, null, i);
				this.get(iter_videos, Column.VIS_TEXT, out text); //, Column.COLL_TYPE, out ct
				if(strcmp(text, "Videos") == 0) {// && ct == CollectionType.LISTED) {
					//found streams
					found = true;
					break;
				}
			}
			if(found == false) {
				Item? item = Item(ItemType.COLLECTION_CONTAINER_VIDEO);
				this.prepend(out iter_videos, null);
				this.set(iter_videos,
				         Column.ICON, videos_pixb,
				         Column.VIS_TEXT, "Videos",
				         Column.ITEM, item
				         );
			}
		}
		foreach(TrackData td in tda) {
			bool visible = false;
			if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
				//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
				visible = true;
//				this.set(iter_videos, Column.VISIBLE, visible);
			}
			this.prepend(out iter_singlevideos, iter_videos);
			this.set(iter_singlevideos,
			         Column.ICON,        video_pixb,
			         Column.VIS_TEXT,    td.title,
			         Column.DRAW_SEPTR,  0,
			         Column.ITEM, td.item
			         );
		}
	}

	public void insert_stream_sorted(TrackData[] tda) {
		string text = null;
		TreeIter iter_radios = TreeIter(), iter_singleradios;
		CollectionType ct = CollectionType.UNKNOWN; 
		if(this.iter_n_children(null) == 0) {
			Item? item = Item(ItemType.COLLECTION_CONTAINER_STREAM);
			this.prepend(out iter_radios, null);
			this.set(iter_radios,
			     Column.ICON, radios_pixb,
			     Column.VIS_TEXT, "Streams",
			     Column.ITEM, item
			     );
		}
		else {
			bool found = false;
			for(int i = 0; i < this.iter_n_children(null); i++) {
				this.iter_nth_child(out iter_radios, null, i);
				this.get(iter_radios, Column.VIS_TEXT, out text); //, Column.COLL_TYPE, out ct
				if(strcmp(text, "Streams") == 0) { // && ct == CollectionType.LISTED) {
					//found streams
					found = true;
					break;
				}
			}
			if(found == false) {
				Item? item = Item(ItemType.COLLECTION_CONTAINER_STREAM);
				this.prepend(out iter_radios, null);
				this.set(iter_radios,
				     Column.ICON, radios_pixb,
				     Column.VIS_TEXT, "Streams",
				     Column.ITEM, item
				     );
			}
		}
		foreach(TrackData td in tda) {
			this.prepend(out iter_singleradios, iter_radios);
			this.set(iter_singleradios,
			         Column.ICON,        radios_pixb,
			         Column.VIS_TEXT,    td.title,
			         Column.ITEM, td.item
			         );
		}
	}

//	public void insert_trackdata_sorted(TrackData[] tda) {
//		TreeIter artist_iter, album_iter;
//		//print("insert_trackdata_sorted : %s - %s - %s - %d \n", tda[0].artist,tda[0].album,tda[0].title,tda[0].db_id);
//		foreach(TrackData td in tda) {
//			//print("XX title: %s\n", td.title);
//			handle_iter_for_artist(ref td, out artist_iter);
//			handle_iter_for_album (ref td, ref artist_iter, out album_iter);
//			handle_iter_for_title (ref td, ref album_iter);
//		}
//	}
	
	// used to move an title iter after editing the tag
	public void move_title_iter_sorted(ref TreeIter org_iter, ref TrackData td) {
		TreeIter artist_iter, album_iter;
		
		handle_iter_for_artist(ref td, out artist_iter);
		handle_iter_for_album (ref td, ref artist_iter, out album_iter);
		
		move_iter_for_title(ref td, ref album_iter , ref org_iter);
	}
	
	// used to move an iter after editing the tag
	private void move_iter_for_title(ref TrackData td, ref TreeIter album_iter, ref TreeIter org_iter) {
		int tr_no = 0;
		TreeIter iter_artist, title_iter;
		int32 dbidx = 0;
		bool visible = false;
		if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
			//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
			visible = true;
//			this.set(album_iter, Column.VISIBLE, visible);
//			if(this.iter_parent(out iter_artist, album_iter))
//				this.set(iter_artist, Column.VISIBLE, visible);
		}
		if(this.iter_n_children(album_iter) == 0) {
//			Item? item = item_handler_manager.create_uri_item(td.uri);
//			item.db_id = td.db_id;
			this.append(out title_iter, album_iter);
			this.set(title_iter,
			         Column.ICON, title_pixb,
			         Column.VIS_TEXT, td.title,
			         Column.ITEM, td.item
			         );
			this.remove(org_iter);
			return;
		}
		for(int i = 0; i < this.iter_n_children(album_iter); i++) {
			this.iter_nth_child(out title_iter, album_iter, i);
			TreeIter parent_of_org_iter;
			this.iter_parent(out parent_of_org_iter, org_iter);
//			this.get(title_iter,  Column.TRACKNUMBER, out tr_no, Column.DB_ID, out dbidx);
//			if(dbidx == td.db_id && parent_of_org_iter != album_iter) {
//				this.remove(org_iter);
//				return; // track is already in target pos 
//			}
//			else if(dbidx == td.db_id && parent_of_org_iter == album_iter) {
//				return; // track is already there 
//			}
			if(tr_no != 0 && tr_no == (int)td.tracknumber) { // tr_no has to be != 0 to be used to sort
				this.remove(org_iter);
				return; // track is already there 
			}
			if(tr_no > (int)td.tracknumber) {
				TreeIter new_title_iter;
				visible = false;
				if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
					//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
					visible = true;
//					this.set(album_iter, Column.VISIBLE, visible);
//					if(this.iter_parent(out iter_artist, album_iter))
//						this.set(iter_artist, Column.VISIBLE, visible);
				}
//				Item? item = item_handler_manager.create_uri_item(td.uri);
//				item.db_id = td.db_id;
				this.insert_before(out new_title_iter, album_iter, title_iter);
				this.set(new_title_iter,
				         Column.ICON, title_pixb,
				         Column.VIS_TEXT, td.title,
				         Column.ITEM, td.item
				         );
				title_iter = new_title_iter;
				this.remove(org_iter);
				return;
			}	
		}
		visible = false;
		if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
			//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
			visible = true;
//			this.set(album_iter, Column.VISIBLE, visible);
//			if(this.iter_parent(out iter_artist, album_iter))
//				this.set(iter_artist, Column.VISIBLE, visible);
		}
//		Item? item = item_handler_manager.create_uri_item(td.uri);
//		item.db_id = td.db_id;
		this.append(out title_iter, album_iter);
		this.set(title_iter,
		         Column.ICON, title_pixb,
		         Column.VIS_TEXT, td.title,
		         Column.ITEM, td.item
		         );
		this.remove(org_iter);
		return;
	}

	// used to move an artist iter after editing the tag
	public void move_artist_iter_sorted(ref TreeIter org_iter, string name) {
		TreeIter artist_iter;
		string text = null;
		CollectionType ct = CollectionType.UNKNOWN;
		for(int i = 0; i < this.iter_n_children(null); i++) {
			this.iter_nth_child(out artist_iter, null, i);
			this.get(artist_iter, Column.VIS_TEXT, out text);
//			if(ct != CollectionType.HIERARCHICAL)
//				continue;
			text = text != null ? text.down().strip() : "";
			if(strcmp(text, name != null ? name.down().strip() : "") == 0 && org_iter != artist_iter) {
				//found artist TODO: recoursive move org_iter content to artist_iter
				return;
			}
			if(strcmp(text, name != null ? name.down().strip() : "") > 0) {
				this.move_before(ref org_iter, artist_iter);
				return;
			}
			if(i == this.iter_n_children(artist_iter) - 1)
				this.move_after(ref org_iter, artist_iter);
		}
	}

	// used to move an artist iter after editing the tag
	public void move_album_iter_sorted(ref TreeIter org_iter, string name) {
		TreeIter artist_iter, album_iter;
		string text = null;
		CollectionType ct = CollectionType.UNKNOWN;
		this.iter_parent(out artist_iter, org_iter);
		for(int i = 0; i < this.iter_n_children(artist_iter); i++) {
			this.iter_nth_child(out album_iter, artist_iter, i);
			this.get(album_iter, Column.VIS_TEXT, out text);
//			if(ct != CollectionType.HIERARCHICAL)
//				continue;
			text = text != null ? text.down().strip() : "";
			if(strcmp(text, name != null ? name.down().strip() : "") == 0 && org_iter != album_iter) {
				//found album TODO: recoursive move org_iter content to album_iter
				return;
			}
			if(strcmp(text, name != null ? name.down().strip() : "") > 0) {
				this.move_before(ref org_iter, album_iter);
				return;
			}
			if(i == this.iter_n_children(artist_iter) - 1)
				this.move_after(ref org_iter, album_iter);
		}
	}

	private void handle_iter_for_artist(ref TrackData td, out TreeIter artist_iter) {
		string text = null;
		TreeIter iter_search;
		if(this.iter_n_children(null) == 0) {
			Item? item = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, td.dat1);
			this.append(out artist_iter, null);
			this.set(artist_iter,
			         Column.ICON, artist_pixb,
			         Column.VIS_TEXT, td.artist,
			         Column.ITEM, item
			         );
			Item? loader_item = Item(ItemType.LOADER);
			this.append(out iter_search, artist_iter);
			this.set(iter_search,
			         Column.ICON, loading_pixb,
			         Column.VIS_TEXT, LOADING,
			         Column.ITEM, loader_item
			         );
			return;
		}
		CollectionType ct = CollectionType.UNKNOWN;
		for(int i = 0; i < this.iter_n_children(null); i++) {
			this.iter_nth_child(out artist_iter, null, i);
			this.get(artist_iter, Column.VIS_TEXT, out text);
//			if(ct != CollectionType.HIERARCHICAL)
//				continue;
			text = text != null ? text.down().strip() : "";
			if(strcmp(text, td.artist != null ? td.artist.down().strip() : "") == 0) {
				//found artist
				return;
			}
			if(strcmp(text, td.artist != null ? td.artist.down().strip() : "") > 0) {
				TreeIter new_artist_iter;
				Item? item = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, td.dat1);
				this.insert_before(out new_artist_iter, null, artist_iter);
				this.set(new_artist_iter,
				         Column.ICON, artist_pixb,
				         Column.VIS_TEXT, td.artist,
				         Column.ITEM, item
				         );
				artist_iter = new_artist_iter;
				Item? loader_item = Item(ItemType.LOADER);
				this.append(out iter_search, artist_iter);
				this.set(iter_search,
					     Column.ICON, loading_pixb,
					     Column.VIS_TEXT, LOADING,
					     Column.ITEM, loader_item
					     );
				return;
			}
		}
		Item? item = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, td.dat1);
		this.append(out artist_iter, null);
		this.set(artist_iter,
		         Column.ICON, artist_pixb,
		         Column.VIS_TEXT, td.artist,
		         Column.ITEM, item
		         );
		Item? loader_item = Item(ItemType.LOADER);
		this.append(out iter_search, artist_iter);
		this.set(iter_search,
		         Column.ICON, loading_pixb,
		         Column.VIS_TEXT, LOADING,
		         Column.ITEM, loader_item
		         );
		return;
	}
	
	private void handle_iter_for_album(ref TrackData td, ref TreeIter artist_iter, out TreeIter album_iter) {
		string text = null;
		//print("--%s\n", td.title);
		bool visible = false;
		if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
			visible = true;
		}
		if(!visible)
			return;
		File? albumimage_file = get_albumimage_for_artistalbum(td.artist, td.album, null);
		Gdk.Pixbuf albumimage = null;
		if(albumimage_file != null) {
			if(albumimage_file.query_exists(null)) {
				try {
					albumimage = new Gdk.Pixbuf.from_file_at_scale(albumimage_file.get_path(), 30, 30, true);
				}
				catch(Error e) {
					albumimage = null;
				}
			}
		}
		if(this.iter_n_children(artist_iter) == 0) {
			Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, td.dat2);
			this.append(out album_iter, artist_iter);
			this.set(album_iter,
			         Column.ICON, (albumimage != null ? albumimage : album_pixb),
			         Column.VIS_TEXT, td.album,
			         Column.ITEM, item
			         );
			return;
		}
		for(int i = 0; i < this.iter_n_children(artist_iter); i++) {
			this.iter_nth_child(out album_iter, artist_iter, i);
			this.get(album_iter, Column.VIS_TEXT, out text);
			text = text != null ? text.down().strip() : "";
			if(strcmp(text, td.album.down().strip()) == 0) {
				//found album
				return;
			}
			if(strcmp(text, td.album.down().strip()) > 0) {
				TreeIter new_album_iter;
				Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, td.dat2);
				this.insert_before(out new_album_iter, artist_iter, album_iter);
				this.set(new_album_iter,
				         Column.ICON, (albumimage != null ? albumimage : album_pixb),
				         Column.VIS_TEXT, td.album,
				         Column.ITEM, item
				         );
				album_iter = new_album_iter;
				return;
			}
		
		}
		Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, td.dat2);
		this.append(out album_iter, artist_iter);
		this.set(album_iter,
		         Column.ICON, (albumimage != null ? albumimage : album_pixb),
		         Column.VIS_TEXT, td.album,
		         Column.ITEM, item
		         );
		return;
	}
	
//	private void handle_iter_for_title(ref TrackData td, ref TreeIter album_iter) {
//		TreeIter title_iter;
//		int tr_no = 0;
//		int32 dbidx = 0;
//		TreeIter iter_artist;
//		bool visible = false;
//		if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
//			visible = true;
//		}
//		if(!visible)
//			return;
//		
//		if(this.iter_n_children(album_iter) == 0) {
//			//print("td.db_id : %d\n", td.db_id);ha
//			if(this.iter_parent(out iter_artist, album_iter))
//				remove_loader_child(ref iter_artist);

//			Item? item = item_handler_manager.create_uri_item(td.uri);
//			item.db_id = td.db_id;
//			this.append(out title_iter, album_iter);
//			this.set(title_iter,
//			         Column.ICON, title_pixb,
//			         Column.VIS_TEXT, td.title,
////			         Column.DB_ID, td.db_id,
////			         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
////			         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
////			         Column.DRAW_SEPTR, 0,
////			         Column.TRACKNUMBER, td.tracknumber,
//			         Column.ITEM, item
//			         );
//			return;
//		}
//		for(int i = 0; i < this.iter_n_children(album_iter); i++) {
//			this.iter_nth_child(out title_iter, album_iter, i);
//			this.get(title_iter, 
////			         Column.TRACKNUMBER, out tr_no,
//			         Column.DB_ID, out dbidx);
//			if(dbidx == td.db_id)
//				return; // track is already there 
//			if(tr_no != 0 && tr_no == (int)td.tracknumber) // tr_no has to be != 0 to be used to sort
//				return; // track is already there 
//			
//			if(tr_no > (int)td.tracknumber) {
//				TreeIter new_title_iter;
//				if(this.iter_parent(out iter_artist, album_iter))
//					remove_loader_child(ref iter_artist);
//				Item? item = item_handler_manager.create_uri_item(td.uri);
//				item.db_id = td.db_id;
//				this.insert_before(out new_title_iter, album_iter, title_iter);
//				this.set(new_title_iter,
//				         Column.ICON, title_pixb,
//				         Column.VIS_TEXT, td.title,
////				         Column.DB_ID, td.db_id,
////				         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
////				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
////				         Column.DRAW_SEPTR, 0,
////				         Column.TRACKNUMBER, td.tracknumber,
//				         Column.ITEM, item
//				         );
//				title_iter = new_title_iter;
//				return;
//			}
//		}
//		visible = false;
//		if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
//			visible = true;
//		}
//		if(this.iter_parent(out iter_artist, album_iter))
//			remove_loader_child(ref iter_artist);
//		if(visible == false)
//			return;
//		Item? item = item_handler_manager.create_uri_item(td.uri);
//		item.db_id = td.db_id;
//		this.append(out title_iter, album_iter);
//		this.set(title_iter,
//		         Column.ICON, title_pixb,
//		         Column.VIS_TEXT, td.title,
////		         Column.DB_ID, td.db_id,
////		         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
////		         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
////		         Column.DRAW_SEPTR, 0,
////		         Column.TRACKNUMBER, td.tracknumber,
//		         Column.ITEM, item
//		         );
//		return;
//	}
	
	public void cancel_fill_model() {
		if(populate_model_cancellable == null)
			return;
		populate_model_cancellable.cancel();
	}
	
	private Cancellable populate_model_cancellable = null;
	public bool populate_model() {
		if(populating_model)
			return false;
		populating_model = true;
		//print("populate_model\n");
		if(populate_model_cancellable == null) {
			populate_model_cancellable = new Cancellable();
		}
		else {
			populate_model_cancellable.reset();
		}
		
		var v_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.handle_listed_data_job);
		v_job.cancellable = populate_model_cancellable;
		db_worker.push_job(v_job);
		
		var a_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_artists_job);
		a_job.cancellable = populate_model_cancellable;
		a_job.finished.connect( (j) => { 
			populating_model = false;
		});
		db_worker.push_job(a_job);
		
		return false;
	}
	
	private bool handle_listed_data_job(Worker.Job job) {
		var stream_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.handle_streams);
		stream_job.cancellable = populate_model_cancellable;
		db_worker.push_job(stream_job);
		
		var video_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.handle_videos);
		video_job.cancellable = populate_model_cancellable;
		db_worker.push_job(video_job);
		return false;
	}
	
	private bool handle_streams(Worker.Job job) {
			
		job.track_dat = db_browser.get_stream_data(ref searchtext);
		
		if(job.track_dat.length == 0)
			return false;
		
		Idle.add( () => {
			if(!job.cancellable.is_cancelled()) {
				TreeIter iter_radios, iter_singleradios;
				Item? item = Item(ItemType.COLLECTION_CONTAINER_STREAM);
				this.prepend(out iter_radios, null);
				this.set(iter_radios,
				         Column.ICON, radios_pixb,
				         Column.VIS_TEXT, "Streams",
				         Column.ITEM, item
				         );
				foreach(TrackData td in job.track_dat) {
					if(job.cancellable.is_cancelled())
						break;
					bool visible = false;
					if(this.searchtext == "" || td.name.down().contains(this.searchtext)) {
						visible = true;
//						this.set(iter_radios, Column.VISIBLE, visible);
					}
					this.prepend(out iter_singleradios, iter_radios);
					this.set(iter_singleradios,
					         Column.ICON,        radios_pixb,
					         Column.VIS_TEXT,    td.name,
					         Column.ITEM, td.item
					         );
				}
			}
			return false;
		});
		return false;
	}
	
	private bool thumbnail_available(string uri, out File? _thumb) {
		string md5string = Checksum.compute_for_string(ChecksumType.MD5, uri);
		File thumb = File.new_for_path(GLib.Path.build_filename(Environment.get_home_dir(), ".thumbnails", "normal", md5string + ".png"));
		if(thumb.query_exists(null)) {
			_thumb = thumb;
			return true;
		}
		_thumb = null;
		return false;
	}
	
	private bool handle_videos(Worker.Job job) {
		int32 cnt = db_browser.count_videos(ref searchtext);
		if(cnt == 0)
			return false;
		Idle.add( () => {
			if(job.cancellable.is_cancelled())
				return false;
			TreeIter iter_videos, iter_loader;
			Item item = Item(ItemType.COLLECTION_CONTAINER_VIDEO);
			this.prepend(out iter_videos, null);
			this.set(iter_videos,
			         Column.ICON, videos_pixb,
			         Column.VIS_TEXT, "Videos",
			         Column.ITEM, item
			         );
			Item? loader_item = Item(ItemType.LOADER);
			this.append(out iter_loader, iter_videos);
			this.set(iter_loader,
			         Column.ICON, loading_pixb,
			         Column.VIS_TEXT, LOADING,
			         Column.ITEM, loader_item
			         );
			return false;
		});
		return false;
	}
	
	private bool load_videos_job(Worker.Job job) {
		job.track_dat = db_browser.get_video_data(ref searchtext);
		
		if(job.track_dat.length == 0)
			return false;
		
		Idle.add( () => {
			TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
			if(row_ref == null || !row_ref.valid())
				return false;
			TreePath p = row_ref.get_path();
			TreeIter iter_videos, iter_singlevideo;
			this.get_iter(out iter_videos, p);
			foreach(unowned TrackData td in job.track_dat) {
				if(job.cancellable.is_cancelled())
					break;
//				bool visible = false;
//				if(this.searchtext == "" || td.name.down().contains(this.searchtext)) {
//					visible = true;
//				}
				Gdk.Pixbuf thumbnail = null;
				File thumb = null;
				bool has_thumbnail = false;
				if(thumbnail_available(td.item.uri, out thumb)) {
					try {
						if(thumb != null) {
							thumbnail = new Gdk.Pixbuf.from_file_at_scale(thumb.get_path(), 30, 30, true);
							has_thumbnail = true;
						}
					}
					catch(Error e) {
						thumbnail = null;
						has_thumbnail = false;
					}
				}
				this.prepend(out iter_singlevideo, iter_videos);
				this.set(iter_singlevideo,
				         Column.ICON, (has_thumbnail == true ? thumbnail : video_pixb),
				         Column.VIS_TEXT, td.name,
				         Column.ITEM, td.item
				         );
			}
			remove_loader_child(ref iter_videos);
			return false;
		});
		return false;
	}

	// used for populating the data model
	private bool populate_artists_job(Worker.Job job) {
		if(job.cancellable.is_cancelled())
			return false;
		
		job.items = db_browser.get_artists_with_search(ref this.searchtext);
		//print("job.items.length = %d\n", job.items.length);
		Idle.add( () => { // TODO Maybe in packages of 1000
			if(job.cancellable.is_cancelled())
				return false;
			TreeIter iter_artist, iter_search;
			foreach(Item? artist in job.items) {
				if(job.cancellable.is_cancelled())
					break;
				this.append(out iter_artist, null);
				this.set(iter_artist,
				         Column.ICON, artist_pixb,
				         Column.VIS_TEXT, artist.text,
				         Column.ITEM, artist
				         );
				Item? loader_item = Item(ItemType.LOADER);
				this.append(out iter_search, iter_artist);
				this.set(iter_search,
				         Column.ICON, loading_pixb,
				         Column.VIS_TEXT, LOADING,
				         Column.ITEM, loader_item
				         );
			}
			return false;
		});
		return false;
	}

	private static const string LOADING = _("Loading ...");
	
	public void unload_children(ref TreeIter iter) {
		TreeIter iter_loader;
		Item? item = Item(ItemType.UNKNOWN);
		this.get(iter, Column.ITEM, out item);
		if(item.type != ItemType.COLLECTION_CONTAINER_ARTIST && 
		   item.type != ItemType.COLLECTION_CONTAINER_VIDEO)
			return;
		Item? loader_item = Item(ItemType.LOADER);
		this.append(out iter_loader, iter);
		this.set(iter_loader,
		         Column.ICON, loading_pixb,
		         Column.VIS_TEXT, LOADING,
		         Column.ITEM, loader_item
		         );
		TreeIter child;
		for(int i = (this.iter_n_children(iter) -2); i >= 0 ; i--) {
			this.iter_nth_child(out child, iter, i);
			this.remove(child);
		}
	}
	
	public void load_children(ref TreeIter iter) {
		if(!row_is_resolved(ref iter))
			load_album_and_titles(ref iter);
	}
	
	private void load_album_and_titles(ref TreeIter iter) {
		//print("load_album_and_titles\n");
		Worker.Job job;
		Item? item = Item(ItemType.UNKNOWN);
		
		TreePath path = this.get_path(iter);
		TreeRowReference treerowref = new TreeRowReference(this, path);
		this.get(iter, Column.ITEM, out item);
		//print("item.type: %s\n", item.type.to_string());
		if(item.type == ItemType.COLLECTION_CONTAINER_ARTIST) {
			job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.load_album_and_titles_job);
			//job.cancellable = populate_model_cancellable;
			job.set_arg("treerowref", treerowref);
			job.set_arg("id", item.db_id);
			db_worker.push_job(job);
		}
		if(item.type == ItemType.COLLECTION_CONTAINER_VIDEO) {
			job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.load_videos_job);
			//job.cancellable = populate_model_cancellable;
			job.set_arg("treerowref", treerowref);
			db_worker.push_job(job);
		}
	}

	private bool load_album_and_titles_job(Worker.Job job) {
		if(this.populating_model)
			return false;
		job.items = db_browser.get_albums_with_search(ref searchtext, (int32)job.get_arg("id"));
		//print("job.items cnt = %d\n", job.items.length);
		Idle.add( () => {
			TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
			if(row_ref == null || !row_ref.valid())
				return false;
			TreePath p = row_ref.get_path();
			TreeIter iter_artist, iter_album;
			this.get_iter(out iter_artist, p);
			Item? artist;
			string artist_name;
			this.get(iter_artist, Column.ITEM, out artist, Column.VIS_TEXT, out artist_name);
			foreach(Item? album in job.items) {     //ALBUMS
				File? albumimage_file = get_albumimage_for_artistalbum(artist_name, album.text, null);
				Gdk.Pixbuf albumimage = null;
				if(albumimage_file != null) {
					if(albumimage_file.query_exists(null)) {
						try {
							albumimage = new Gdk.Pixbuf.from_file_at_scale(albumimage_file.get_path(), 30, 30, true);
						}
						catch(Error e) {
							albumimage = null;
						}
					}
				}
				this.append(out iter_album, iter_artist);
				this.set(iter_album,
				         Column.ICON, (albumimage != null ? albumimage : album_pixb),
				         Column.VIS_TEXT, album.text,
				         Column.ITEM, album
				         );
				Gtk.TreePath p1 = this.get_path(iter_album);
				TreeRowReference treerowref = new TreeRowReference(this, p1);
				var job_title = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_title_job);
				job_title.set_arg("treerowref", treerowref);
				job_title.set_arg("artist", artist.db_id);
				job_title.set_arg("album", album.db_id);
				db_worker.push_job(job_title);
			}
			remove_loader_child(ref iter_artist);
			return false;
		});
		return false;
	}
	
	private void remove_loader_child(ref TreeIter iter) {
		TreeIter child;
		Item? item;
		for(int i = (this.iter_n_children(iter) - 1); i >= 0 ; i--) {
			this.iter_nth_child(out child, iter, i);
			this.get(child, Column.ITEM, out item);
			if(item.type == ItemType.LOADER) {
				this.remove(child);
				return;
			}
		}
	}
	
	private bool row_is_resolved(ref TreeIter iter) {
		if(this.iter_n_children(iter) != 1)
			return true;
		TreeIter child;
		Item? item = Item(ItemType.UNKNOWN);
		this.iter_nth_child(out child, iter, 0);
		this.get(child, MediaBrowserModel.Column.ITEM, out item);
		return (item.type != ItemType.LOADER);
	}

	private void update_album_image() {
		TreeIter artist_iter = TreeIter(), album_iter;
		if(!global.media_import_in_progress) {
			string text = null;
			//print("--%s\n", td.title);
			string artist = global.current_artist;
			string album = global.current_album;
			File? albumimage_file = get_albumimage_for_artistalbum(artist, album, null);
			Gdk.Pixbuf albumimage = null;
			if(albumimage_file != null) {
				if(albumimage_file.query_exists(null)) {
					try {
						albumimage = new Gdk.Pixbuf.from_file_at_scale(albumimage_file.get_path(), 30, 30, true);
					}
					catch(Error e) {
						albumimage = null;
					}
				}
			}
			for(int i = 0; i < this.iter_n_children(null); i++) {
				this.iter_nth_child(out artist_iter, null, i);
				this.get(artist_iter, Column.VIS_TEXT, out text);
				text = text != null ? text.down().strip() : "";
				if(strcmp(text, artist != null ? artist.down().strip() : "") == 0) {
					//found artist
					break;
				}
				if(i == (this.iter_n_children(null) - 1))
					return;
			}
			for(int i = 0; i < this.iter_n_children(artist_iter); i++) {
				this.iter_nth_child(out album_iter, artist_iter, i);
				this.get(album_iter, Column.VIS_TEXT, out text);
				text = text != null ? text.down().strip() : "";
				if(strcmp(text, album != null ? album.down().strip() : "") == 0) {
					//found album
					this.set(album_iter,
							 Column.ICON, (albumimage != null ? albumimage : album_pixb)
							 );
					break;
				}
			}
		}
	}
	

	//Used for populating model
	private bool populate_title_job(Worker.Job job) {
		if(this.populating_model)
			return false;
		int32 al = (int32)job.get_arg("album");
		job.track_dat = db_browser.get_trackdata_by_albumid(ref searchtext, al);
		Idle.add( () => {
			TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
			if((row_ref == null) || (!row_ref.valid()))
				return false;
			TreePath p = row_ref.get_path();
			TreeIter iter_title, iter_album;
			this.get_iter(out iter_album, p);
			foreach(unowned TrackData td in job.track_dat) {
				Gdk.Pixbuf thumbnail = null;
				bool has_thumbnail = false;
				if(td.item.type == ItemType.LOCAL_VIDEO_TRACK) {
					File thumb = null;
					if(thumbnail_available(td.item.uri, out thumb)) {
						try {
							if(thumb != null) {
								thumbnail = new Gdk.Pixbuf.from_file_at_scale(thumb.get_path(), 30, 30, true);
								has_thumbnail = true;
							}
						}
						catch(Error e) {
							thumbnail = null;
							has_thumbnail = false;
						}
					}
				}
				this.append(out iter_title, iter_album);
				this.set(iter_title,
				         Column.ICON, (td.item.type == ItemType.LOCAL_AUDIO_TRACK ? title_pixb : (has_thumbnail == true ? thumbnail : video_pixb)),
				         Column.VIS_TEXT, td.title,
				         Column.ITEM, td.item
				         );
			}
			return false;
		});
		return false;
	}

	//TODO: How to do this for videos/streams?
	public DndData[] get_dnd_data_for_path(ref TreePath treepath) {
		TreeIter iter;//, iterChild, iterChildChild;
		DndData[] dnd_data_array = {};
		Item? item = null;
		this.get_iter(out iter, treepath);
		this.get(iter, Column.ITEM, out item);
		if(item != null && item.db_id != -1) {
			DndData dnd_data = { item.db_id, item.type };//{ dbid, (ItemType)mtype };
			dnd_data_array += dnd_data;
		}
		return dnd_data_array;
	}
}
