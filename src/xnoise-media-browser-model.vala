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
		DB_ID,
		MEDIATYPE,
		COLL_TYPE,
		DRAW_SEPTR,
		VISIBLE,
		TRACKNUMBER,
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
		typeof(int),        //DB_ID
		typeof(int),        //MEDIATYPE
		typeof(int),        //COLL_TYPE
		typeof(int),        //DRAW SEPARATOR
		typeof(bool),       //VISIBLE
		typeof(int),        //TRACKNUMBER
		typeof(Xnoise.Item) //ITEM
	};

	public string searchtext = "";
	private unowned IconTheme theme = null;
	private Gdk.Pixbuf artist_pixb;
	private Gdk.Pixbuf album_pixb;
	private Gdk.Pixbuf title_pixb;
	private Gdk.Pixbuf video_pixb;
	private Gdk.Pixbuf videos_pixb;
	private Gdk.Pixbuf radios_pixb;
	private unowned Main xn;
	
	public bool populating_model { get; private set; default = false; }
	
	construct {
		xn = Main.instance;
		theme = IconTheme.get_default();
		theme.changed.connect(update_pixbufs);
		set_pixbufs();
		set_column_types(col_types);
		global.notify["image-path-small"].connect( () => {
			Timeout.add(5, () => {
				update_album_image();
				return false;
			});
		});
		this.notify["populating-model"].connect( () => {
			if(this.populating_model)
				return;
			Timeout.add(250, () => {
				// print("refreshing search ...\n");
				Main.instance.main_window.mediaBr.on_searchtext_changed();
				return false;
			});
		});
		global.notify["media-import-in-progress"].connect( () => {
			if(global.media_import_in_progress)
				return;
			Timeout.add(250, () => {
				//print("refreshing search ...\n");
				Main.instance.main_window.mediaBr.on_searchtext_changed();
				return false;
			});
		});
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
		switch(path.get_depth()) {
			case 1: //ARTIST
				string artist = null;
				this.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref artist);
				if(artist != null && artist.down().contains(searchtext) == true) {
					this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
					return false;
				}
				TreeIter iterChild;
				for(int i = 0; i < this.iter_n_children(iter); i++) {
					this.iter_nth_child(out iterChild, iter, i);
					string album = null;
					this.get(iterChild, MediaBrowserModel.Column.VIS_TEXT, ref album);
					if(album != null && album.down().contains(searchtext) == true) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
					TreeIter iterChildChild;
					for(int j = 0; j < this.iter_n_children(iterChild); j++) {
						this.iter_nth_child(out iterChildChild, iterChild, j);
						string title = null;
						this.get(iterChildChild, MediaBrowserModel.Column.VIS_TEXT, ref title);
						if(title != null && title.down().contains(searchtext) == true) {
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
				if(album != null && album.down().contains(searchtext) == true) {
					this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
					return false;
				}
				TreeIter iterChild;
				for(int i = 0; i < this.iter_n_children(iter); i++) {
					this.iter_nth_child(out iterChild, iter, i);
					string title = null;
					this.get(iterChild, MediaBrowserModel.Column.VIS_TEXT, ref title);
					if(title != null && title.down().contains(searchtext) == true) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
				}
				TreeIter iter_parent;
				string artist = null;
				if(this.iter_parent(out iter_parent, iter)) {
					this.get(iter_parent, MediaBrowserModel.Column.VIS_TEXT, ref artist);
					if(artist != null && artist.down().contains(searchtext) == true) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
				}
				this.set(iter, MediaBrowserModel.Column.VISIBLE, false);
				return false;
			case 3: //TITLE
				string title = null;
				this.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref title);
				if(title != null && title.down().contains(searchtext) == true) {
					this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
					return false;
				}
				TreeIter iter_parent;
				string album = null;
				if(this.iter_parent(out iter_parent, iter)) {
					this.get(iter_parent, MediaBrowserModel.Column.VIS_TEXT, ref album);
					if(album != null && album.down().contains(searchtext) == true) {
						this.set(iter, MediaBrowserModel.Column.VISIBLE, true);
						return false;
					}
					TreeIter iter_parent_parent;
					string artist = null;
					if(this.iter_parent(out iter_parent_parent, iter_parent)) {
						this.get(iter_parent_parent, MediaBrowserModel.Column.VIS_TEXT, ref artist);
						if(artist != null && artist.down().contains(searchtext) == true) {
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
			this.prepend(out iter_videos, null);
			this.set(iter_videos,
			         Column.ICON, videos_pixb,
			         Column.VIS_TEXT, "Videos",
			         Column.COLL_TYPE, CollectionType.LISTED,
			         Column.DRAW_SEPTR, 0,
			         Column.VISIBLE, false
			         );
		}
		else {
			bool found = false;
			for(int i = 0; i < this.iter_n_children(null); i++) {
				this.iter_nth_child(out iter_videos, null, i);
				this.get(iter_videos, Column.VIS_TEXT, ref text, Column.COLL_TYPE, ref ct);
				if(strcmp(text, "Videos") == 0 && ct == CollectionType.LISTED) {
					//found streams
					found = true;
					break;
				}
			}
			if(found == false) {
				this.prepend(out iter_videos, null);
				this.set(iter_videos,
					     Column.ICON, videos_pixb,
					     Column.VIS_TEXT, "Videos",
					     Column.COLL_TYPE, CollectionType.LISTED,
					     Column.DRAW_SEPTR, 0,
					     Column.VISIBLE, false
					     );
			}
		}
		foreach(TrackData td in tda) {
			bool visible = false;
			if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
				//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
				visible = true;
				this.set(iter_videos, Column.VISIBLE, visible);
			}
			this.prepend(out iter_singlevideos, iter_videos);
			this.set(iter_singlevideos,
			         Column.ICON,        videos_pixb,
			         Column.VIS_TEXT,    td.title,
			         Column.DB_ID,       td.db_id,
			         Column.MEDIATYPE ,  ItemType.LOCAL_VIDEO_TRACK,
			         Column.COLL_TYPE,   CollectionType.LISTED,
			         Column.DRAW_SEPTR,  0,
			         Column.VISIBLE, visible
			         );
		}
	}

	public void insert_stream_sorted(TrackData[] tda) {
		string text = null;
		TreeIter iter_radios = TreeIter(), iter_singleradios;
		CollectionType ct = CollectionType.UNKNOWN; 
		if(this.iter_n_children(null) == 0) {
			this.prepend(out iter_radios, null);
			this.set(iter_radios,
			     Column.ICON, radios_pixb,
			     Column.VIS_TEXT, "Streams",
			     Column.COLL_TYPE, CollectionType.LISTED,
			     Column.DRAW_SEPTR, 0,
			     Column.VISIBLE, true
			     );
		}
		else {
			bool found = false;
			for(int i = 0; i < this.iter_n_children(null); i++) {
				this.iter_nth_child(out iter_radios, null, i);
				this.get(iter_radios, Column.VIS_TEXT, ref text, Column.COLL_TYPE, ref ct);
				if(strcmp(text, "Streams") == 0 && ct == CollectionType.LISTED) {
					//found streams
					found = true;
					break;
				}
			}
			if(found == false) {
				this.prepend(out iter_radios, null);
				this.set(iter_radios,
					 Column.ICON, radios_pixb,
					 Column.VIS_TEXT, "Streams",
					 Column.COLL_TYPE, CollectionType.LISTED,
					 Column.DRAW_SEPTR, 0,
					 Column.VISIBLE, true
					 );
			}
		}
		foreach(TrackData td in tda) {
			this.prepend(out iter_singleradios, iter_radios);
			this.set(iter_singleradios,
			         Column.ICON,        radios_pixb,
			         Column.VIS_TEXT,    td.title,
			         Column.DB_ID,       td.db_id,
			         Column.MEDIATYPE ,  (int)ItemType.STREAM,
			         Column.COLL_TYPE,   CollectionType.LISTED,
			         Column.DRAW_SEPTR,  0,
			         Column.VISIBLE, true
			         );
		}
	}

	public void insert_trackdata_sorted(TrackData[] tda) {
		TreeIter artist_iter, album_iter, title_iter;
		//print("insert_trackdata_sorted : %s - %s - %s - %d \n", tda[0].artist,tda[0].album,tda[0].title,tda[0].db_id);
		foreach(TrackData td in tda) {
			//print("XX title: %s\n", td.title);
			handle_iter_for_artist(ref td, out artist_iter);
			handle_iter_for_album (ref td, ref artist_iter, out album_iter);
			handle_iter_for_title (ref td, ref album_iter , out title_iter);
		}
	}
	
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
			this.set(album_iter, Column.VISIBLE, visible);
			if(this.iter_parent(out iter_artist, album_iter))
				this.set(iter_artist, Column.VISIBLE, visible);
		}
		if(this.iter_n_children(album_iter) == 0) {
			this.append(out title_iter, album_iter);
			this.set(title_iter,
			         Column.ICON, title_pixb,
			         Column.VIS_TEXT, td.title,
			         Column.DB_ID, td.db_id,
			         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
			         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
			         Column.DRAW_SEPTR, 0,
			         Column.VISIBLE, visible,
			         Column.TRACKNUMBER, td.tracknumber,
			         Column.ITEM, item_handler_manager.create_uri_item(td.uri)
			         );
			this.remove(org_iter);
			return;
		}
		for(int i = 0; i < this.iter_n_children(album_iter); i++) {
			this.iter_nth_child(out title_iter, album_iter, i);
			TreeIter parent_of_org_iter;
			this.iter_parent(out parent_of_org_iter, org_iter);
			this.get(title_iter,  Column.TRACKNUMBER, ref tr_no, Column.DB_ID, ref dbidx);
			if(dbidx == td.db_id && parent_of_org_iter != album_iter) {
				this.remove(org_iter);
				return; // track is already in target pos 
			}
			else if(dbidx == td.db_id && parent_of_org_iter == album_iter) {
				return; // track is already there 
			}
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
					this.set(album_iter, Column.VISIBLE, visible);
					if(this.iter_parent(out iter_artist, album_iter))
						this.set(iter_artist, Column.VISIBLE, visible);
				}
				this.insert_before(out new_title_iter, album_iter, title_iter);
				this.set(new_title_iter,
				         Column.ICON, title_pixb,
				         Column.VIS_TEXT, td.title,
				         Column.DB_ID, td.db_id,
				         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, visible,
				         Column.TRACKNUMBER, td.tracknumber,
				         Column.ITEM, item_handler_manager.create_uri_item(td.uri)
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
			this.set(album_iter, Column.VISIBLE, visible);
			if(this.iter_parent(out iter_artist, album_iter))
				this.set(iter_artist, Column.VISIBLE, visible);
		}
		this.append(out title_iter, album_iter);
		this.set(title_iter,
		         Column.ICON, title_pixb,
		         Column.VIS_TEXT, td.title,
		         Column.DB_ID, td.db_id,
		         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
		         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
		         Column.DRAW_SEPTR, 0,
		         Column.VISIBLE, visible,
		         Column.TRACKNUMBER, td.tracknumber,
		         Column.ITEM, item_handler_manager.create_uri_item(td.uri)
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
			this.get(artist_iter, Column.VIS_TEXT, ref text, Column.COLL_TYPE, ref ct);
			if(ct != CollectionType.HIERARCHICAL)
				continue;
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
			this.get(album_iter, Column.VIS_TEXT, ref text, Column.COLL_TYPE, ref ct);
			if(ct != CollectionType.HIERARCHICAL)
				continue;
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
		if(this.iter_n_children(null) == 0) {
			Item item = Item(ItemType.COLLECTION_CONTAINER_ARTIST);
			this.append(out artist_iter, null);
			this.set(artist_iter,
			         Column.ICON, artist_pixb,
			         Column.VIS_TEXT, td.artist,
			         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
			         Column.DRAW_SEPTR, 0,
			         Column.VISIBLE, false,
			         Column.ITEM, item
			         );
			return;
		}
		CollectionType ct = CollectionType.UNKNOWN;
		for(int i = 0; i < this.iter_n_children(null); i++) {
			this.iter_nth_child(out artist_iter, null, i);
			this.get(artist_iter, Column.VIS_TEXT, ref text, Column.COLL_TYPE, ref ct);
			if(ct != CollectionType.HIERARCHICAL)
				continue;
			text = text != null ? text.down().strip() : "";
			if(strcmp(text, td.artist != null ? td.artist.down().strip() : "") == 0) {
				//found artist
				return;
			}
			if(strcmp(text, td.artist != null ? td.artist.down().strip() : "") > 0) {
				TreeIter new_artist_iter;
				Item item = Item(ItemType.COLLECTION_CONTAINER_ARTIST);
				this.insert_before(out new_artist_iter, null, artist_iter);
				this.set(new_artist_iter,
				         Column.ICON, artist_pixb,
				         Column.VIS_TEXT, td.artist,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, false,
				         Column.ITEM, item
				         );
				artist_iter = new_artist_iter;
				return;
			}
		}
		Item item = Item(ItemType.COLLECTION_CONTAINER_ARTIST);
		this.append(out artist_iter, null);
		this.set(artist_iter,
		         Column.ICON, artist_pixb,
		         Column.VIS_TEXT, td.artist,
		         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
		         Column.DRAW_SEPTR, 0,
		         Column.VISIBLE, false,
		         Column.ITEM, item
		         );
		return;
	}
	
	private void handle_iter_for_album(ref TrackData td, ref TreeIter artist_iter, out TreeIter album_iter) {
		string text = null;
		//print("--%s\n", td.title);
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
			Item item = Item(ItemType.COLLECTION_CONTAINER_ALBUM);
			this.append(out album_iter, artist_iter);
			this.set(album_iter,
			         Column.ICON, (albumimage != null ? albumimage : album_pixb),
			         Column.VIS_TEXT, td.album,
			         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
			         Column.DRAW_SEPTR, 0,
			         Column.VISIBLE, false,
			         Column.ITEM, item
			         );
			return;
		}
		for(int i = 0; i < this.iter_n_children(artist_iter); i++) {
			this.iter_nth_child(out album_iter, artist_iter, i);
			this.get(album_iter, Column.VIS_TEXT, ref text);
			text = text != null ? text.down().strip() : "";
			if(strcmp(text, td.album.down().strip()) == 0) {
				//found album
				return;
			}
			if(strcmp(text, td.album.down().strip()) > 0) {
				TreeIter new_album_iter;
				Item item = Item(ItemType.COLLECTION_CONTAINER_ALBUM);
				this.insert_before(out new_album_iter, artist_iter, album_iter);
				this.set(new_album_iter,
				         Column.ICON, (albumimage != null ? albumimage : album_pixb),
				         Column.VIS_TEXT, td.album,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, false,
				         Column.ITEM, item
				         );
				album_iter = new_album_iter;
				return;
			}
		
		}
		Item item = Item(ItemType.COLLECTION_CONTAINER_ALBUM);
		this.append(out album_iter, artist_iter);
		this.set(album_iter,
		         Column.ICON, (albumimage != null ? albumimage : album_pixb),
		         Column.VIS_TEXT, td.album,
		         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
		         Column.DRAW_SEPTR, 0,
		         Column.VISIBLE, false,
		         Column.ITEM, item
		         );
		return;
	}
	
	private void handle_iter_for_title(ref TrackData td, ref TreeIter album_iter, out TreeIter title_iter) {
		int tr_no = 0;
		int32 dbidx = 0;
		TreeIter iter_artist;
		bool visible = false;
		if(this.iter_n_children(album_iter) == 0) {
			//print("td.db_id : %d\n", td.db_id);ha
			visible = false;
			if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
				//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
				visible = true;
				this.set(album_iter, Column.VISIBLE, visible);
				if(this.iter_parent(out iter_artist, album_iter))
					this.set(iter_artist, Column.VISIBLE, visible);
			}
			Item item = item_handler_manager.create_uri_item(td.uri);
			this.append(out title_iter, album_iter);
			this.set(title_iter,
			         Column.ICON, title_pixb,
			         Column.VIS_TEXT, td.title,
			         Column.DB_ID, td.db_id,
			         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
			         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
			         Column.DRAW_SEPTR, 0,
			         Column.VISIBLE, visible,
			         Column.TRACKNUMBER, td.tracknumber,
			         Column.ITEM, item
			         );
			return;
		}
		for(int i = 0; i < this.iter_n_children(album_iter); i++) {
			this.iter_nth_child(out title_iter, album_iter, i);
			this.get(title_iter, 
			         Column.TRACKNUMBER, ref tr_no,
			         Column.DB_ID, ref dbidx);
			if(dbidx == td.db_id)
				return; // track is already there 
			if(tr_no != 0 && tr_no == (int)td.tracknumber) // tr_no has to be != 0 to be used to sort
				return; // track is already there 
			
			if(tr_no > (int)td.tracknumber) {
				TreeIter new_title_iter;
				visible = false;
				if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
					//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
					visible = true;
					this.set(album_iter, Column.VISIBLE, visible);
					if(this.iter_parent(out iter_artist, album_iter))
						this.set(iter_artist, Column.VISIBLE, visible);
				}
				Item item = item_handler_manager.create_uri_item(td.uri);
				this.insert_before(out new_title_iter, album_iter, title_iter);
				this.set(new_title_iter,
				         Column.ICON, title_pixb,
				         Column.VIS_TEXT, td.title,
				         Column.DB_ID, td.db_id,
				         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, visible,
				         Column.TRACKNUMBER, td.tracknumber,
				         Column.ITEM, item
				         );
				title_iter = new_title_iter;
				return;
			}
		}
		visible = false;
		if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
			//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
			visible = true;
			this.set(album_iter, Column.VISIBLE, visible);
			if(this.iter_parent(out iter_artist, album_iter))
				this.set(iter_artist, Column.VISIBLE, visible);
		}
		Item item = item_handler_manager.create_uri_item(td.uri);
		this.append(out title_iter, album_iter);
		this.set(title_iter,
		         Column.ICON, title_pixb,
		         Column.VIS_TEXT, td.title,
		         Column.DB_ID, td.db_id,
		         Column.MEDIATYPE , ItemType.LOCAL_AUDIO_TRACK,
		         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
		         Column.DRAW_SEPTR, 0,
		         Column.VISIBLE, visible,
		         Column.TRACKNUMBER, td.tracknumber,
		         Column.ITEM, item
		         );
		return;
	}
	
	public void cancel_fill_model() {
		if(populate_model_cancellable == null)
			return;
		populate_model_cancellable.cancel();
	}
	
	private Cancellable populate_model_cancellable = null;
	public bool populate_model() {
		populating_model = true;
		//print("populate_model\n");
		if(populate_model_cancellable == null) {
			populate_model_cancellable = new Cancellable();
		}
		else {
			populate_model_cancellable.reset();
		}
		Worker.Job job;
		job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_listed_data_job);
		job.cancellable = populate_model_cancellable;
		worker.push_job(job);
		
		job = new Worker.Job(1, Worker.ExecutionType.REPEATED, this.handle_hierarchical_data_job, null);
		job.cancellable = populate_model_cancellable;
		job.finished.connect( (j) => { 
			populating_model = false;
		});
		worker.push_job(job);
		
		return false;
	}
	
	private void handle_listed_data_job(Worker.Job job) {
		var stream_job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_streams);
		stream_job.cancellable = populate_model_cancellable;
		worker.push_job(stream_job);
		
		var video_job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_videos);
		video_job.cancellable = populate_model_cancellable;
		worker.push_job(video_job);
	}
	
	private void handle_streams(Worker.Job job) {
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}		
		job.track_dat = dbb.get_stream_data(ref searchtext);
		
		if(job.track_dat.length == 0)
			return;
		
		Idle.add( () => {
			if(!job.cancellable.is_cancelled()) {
				TreeIter iter_radios, iter_singleradios;
				this.prepend(out iter_radios, null);
				this.set(iter_radios,
				         Column.ICON, radios_pixb,
				         Column.VIS_TEXT, "Streams",
				         Column.COLL_TYPE, CollectionType.LISTED,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, true
				         );
				foreach(TrackData td in job.track_dat) {
					if(job.cancellable.is_cancelled())
						break;
					bool visible = false;
					if(this.searchtext == "" || td.name.down().contains(this.searchtext)) {
						visible = true;
						this.set(iter_radios, Column.VISIBLE, visible);
					}
					this.prepend(out iter_singleradios, iter_radios);
					this.set(iter_singleradios,
					         Column.ICON,        radios_pixb,
					         Column.VIS_TEXT,    td.name,
					         Column.DB_ID,       td.db_id,
					         Column.MEDIATYPE ,  (int)ItemType.STREAM,
					         Column.COLL_TYPE,   CollectionType.LISTED,
					         Column.DRAW_SEPTR,  0,
					         Column.VISIBLE, true
					         );
				}
			}
			return false;
		});
	}
	
	private void handle_videos(Worker.Job job) {
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}		
		job.track_dat = dbb.get_video_data(ref searchtext);
		
		if(job.track_dat.length == 0)
			return;
		
		Idle.add( () => {
			if(!job.cancellable.is_cancelled()) {
				TreeIter iter_videos, iter_singlevideo;
				this.prepend(out iter_videos, null);
				this.set(iter_videos,
						 Column.ICON, videos_pixb,
						 Column.VIS_TEXT, "Videos",
						 Column.COLL_TYPE, CollectionType.LISTED,
						 Column.DRAW_SEPTR, 0,
						 Column.VISIBLE, false
						 );
				foreach(unowned TrackData td in job.track_dat) {
					if(job.cancellable.is_cancelled())
						break;
					bool visible = false;
					if(this.searchtext == "" || td.name.down().contains(this.searchtext)) {
						visible = true;
						this.set(iter_videos, Column.VISIBLE, visible);
					}
					this.prepend(out iter_singlevideo, iter_videos);
					this.set(iter_singlevideo,
					         Column.ICON, video_pixb,
					         Column.VIS_TEXT, td.name,
					         Column.DB_ID, td.db_id,
					         Column.MEDIATYPE , (int) ItemType.LOCAL_VIDEO_TRACK,
					         Column.COLL_TYPE, CollectionType.LISTED,
					         Column.DRAW_SEPTR, 0,
					         Column.VISIBLE, visible
					         );
				}
			}
			return false;
		});
	}

	// used for populating the data model
	private bool handle_hierarchical_data_job(Worker.Job job) {
	//repeat until returns false
		DbBrowser dbb = null;
		if(job.cancellable.is_cancelled())
			return false;
		
		if(dbb == null) {
			try {
				dbb = new DbBrowser();
			}
			catch(DbError e) {
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
				catch(DbError e) {
					print("%s\n", e.message);
					dbb = null;
					return false;
				}
				if(dbb == null) {
					print("unable to get DB handle\n");
					return false;
				}
			}
			job.big_counter[0] = (int32)dbb.count_artists(); // search needed ? 
		}
		
		if(job.big_counter[0] == 0) {
			dbb = null;
			return false;
		}
		bool repeate = true;
		if((job.big_counter[1] + ARTIST_FOR_ONE_JOB) > job.big_counter[0]) {
			// last round
			dbb = null;
			repeate = false;
		}

		var artist_job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_artists);
		artist_job.cancellable = populate_model_cancellable;
		artist_job.big_counter[1] = job.big_counter[1]; //current offset
		
		if(job.cancellable.is_cancelled())
			return false;
		
		worker.push_job(artist_job);
		
		// increment offset
		job.big_counter[1] = job.big_counter[1] + ARTIST_FOR_ONE_JOB;
		
		return repeate;
	}
	
	private const int ARTIST_FOR_ONE_JOB = 12;
	//Used for populating model
	private void handle_artists(Worker.Job job) {
		if(job.cancellable == null || job.cancellable.is_cancelled())
			return;
		string[] artistArray;
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}
		artistArray = dbb.get_some_artists(ARTIST_FOR_ONE_JOB, job.big_counter[1]);
		//print("artistArray lenght init %d\n", artistArray.length);
		job.big_counter[1] += artistArray.length;
		
		job.set_arg("artistArray", artistArray);
		Idle.add( () => {
			if(job.cancellable.is_cancelled())
				return false;
			TreeIter iter_artist;
			foreach(string artist in (string[])job.get_arg("artistArray")) { 	              //ARTISTS
				if(job.cancellable.is_cancelled())
					break;
				Item item = Item(ItemType.COLLECTION_CONTAINER_ARTIST);
				this.append(out iter_artist, null);
				this.set(iter_artist,
				         Column.ICON, artist_pixb,
				         Column.VIS_TEXT, artist,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, false,
				         Column.ITEM, item
				         );
				
				Gtk.TreePath p = this.get_path(iter_artist);
				TreeRowReference treerowref = new TreeRowReference(this, p);
				var job_album = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_album);
				job_album.cancellable = populate_model_cancellable;
				job_album.set_arg("treerowref", treerowref);
				job_album.set_arg("artist", artist);
				worker.push_job(job_album);
			}
			return false;
		});
		return;
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
				this.get(artist_iter, Column.VIS_TEXT, ref text);
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
				this.get(album_iter, Column.VIS_TEXT, ref text);
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
	private void handle_album(Worker.Job job) {
		if(job.cancellable.is_cancelled())
			return;
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}		
		string artist = (string)job.get_arg("artist");
		string[] albumArray = dbb.get_albums(artist);
		
		job.set_arg("albumArray", albumArray);
		Idle.add( () => {
				if(job.cancellable.is_cancelled())
					return false;
				TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
				TreePath p = row_ref.get_path();
				TreeIter iter_artist, iter_album;
				this.get_iter(out iter_artist, p);
				foreach(string album in (string[])job.get_arg("albumArray")) { 			    //ALBUMS
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
					if(job.cancellable.is_cancelled())
						return false;
					Item item = Item(ItemType.COLLECTION_CONTAINER_ALBUM);
					this.prepend(out iter_album, iter_artist);
					this.set(iter_album,
					         Column.ICON, (albumimage != null ? albumimage : album_pixb),
					         Column.VIS_TEXT, album,
					         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
					         Column.DRAW_SEPTR, 0,
					         Column.VISIBLE, false,
					         Column.ITEM, item
					         );
					Gtk.TreePath p1 = this.get_path(iter_album);
					TreeRowReference treerowref = new TreeRowReference(this, p1);
					var job_title = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_titles);
					job_title.cancellable = populate_model_cancellable;
					job_title.set_arg("treerowref", treerowref);
					job_title.set_arg("artist", artist);
					job_title.set_arg("album", album);
					worker.push_job(job_title);
				}
			return false;
		});
	}

	//Used for populating model
	private void handle_titles(Worker.Job job) {
		if(job.cancellable.is_cancelled())
			return;
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}
		string ar, al;
		ar = (string)job.get_arg("artist");
		al = (string)job.get_arg("album");
		job.track_dat = dbb.get_titles_with_data(ar, al);
		
		Idle.add( () => {
			if(job.cancellable.is_cancelled())
				return false;
			TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
			TreePath p = row_ref.get_path();
			TreeIter iter_title, iter_album, iter_artist;
			this.get_iter(out iter_album, p);
			foreach(unowned TrackData td in job.track_dat) {	         //TITLES
				if(job.cancellable.is_cancelled())
					return false;
				bool visible = false;
				if(this.searchtext == "" || td.artist.down().contains(this.searchtext) || td.album.down().contains(this.searchtext) || td.title.down().contains(this.searchtext)) {
					//print("visible for %s-%s-%s    %s\n", td.artist, td.album, td.title, this.searchtext);
					visible = true;
					this.set(iter_album, Column.VISIBLE, visible);
					if(this.iter_parent(out iter_artist, iter_album))
						this.set(iter_artist, Column.VISIBLE, visible);
				}
				Item item = Item((td.mediatype == ItemType.LOCAL_AUDIO_TRACK ? ItemType.LOCAL_AUDIO_TRACK : ItemType.LOCAL_VIDEO_TRACK), td.uri, td.db_id);
				this.prepend(out iter_title, iter_album);
				this.set(iter_title,
				         Column.ICON, (td.mediatype == ItemType.LOCAL_AUDIO_TRACK ? title_pixb : video_pixb),
				         Column.VIS_TEXT, td.title,
				         Column.DB_ID, td.db_id,
				         Column.MEDIATYPE , td.mediatype,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0,
				         Column.VISIBLE, visible,
				         Column.TRACKNUMBER, td.tracknumber,
				         Column.ITEM, item
				         );
			}
			return false;
		});
	}

	private void queue_listed_data_job(Worker.Job job) {
		TrackData[] tda = {};// job.track_dat;
		Item[] ita = {};
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}
		foreach(TrackData td in job.track_dat) {
			if(td.db_id > 0) {
				TrackData tdl;
				switch(td.mediatype) {
					case ItemType.LOCAL_VIDEO_TRACK: {
						if(dbb.get_trackdata_for_id(td.db_id, out tdl))
							ita += item_handler_manager.create_uri_item(td.uri);
							tda += tdl;
						break;
					}
					case ItemType.STREAM: {
						if(dbb.get_stream_td_for_id(td.db_id, out tdl))
							ita += item_handler_manager.create_uri_item(td.uri);
							tda += tdl;
						break;
					}
					default:
						break;
				}
			}
		}
		job.track_dat = tda;
		job.items = ita;
		//Add tracks in default thread
		Idle.add( () => {
			xn.tl.tracklistmodel.add_tracks(job.track_dat, true);
			job.track_dat = null;
//			job.media_dat = null;
			return false;
		});
	}
	
	private void get_mediadata_of_listed(ref TrackData[] mda, Gtk.TreePath treepath) {
		//this is only used for path.get_depth() == 2 !
		TreeIter iter;
		TrackData[] mda_local = {};// = mda;
		TrackData md = new TrackData();
		md.db_id = -1;
		bool visible = false;
		this.get_iter(out iter, treepath);
		this.get(iter,
		         Column.VIS_TEXT,  ref md.name,
		         Column.DB_ID,     ref md.db_id,
		         Column.MEDIATYPE, ref md.mediatype,
		         Column.VISIBLE, ref visible
		         );
		if(md.db_id > -1 && visible)
			mda_local += md;
		
		mda = mda_local;
	}
	
	private void queue_hierarchical_data_job(Worker.Job job) {
		TrackData[] tda = {};//job.track_dat;
		Item[] ita = {};
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}
		foreach(TrackData md in job.track_dat) {
			TrackData td;
			if(dbb.get_trackdata_for_id(md.db_id, out td)) {
				Item it = item_handler_manager.create_uri_item(td.uri);
				td.item = it;
				tda += td;
			}
		}
		job.track_dat = tda;
		//Add tracks in default thread
		Idle.add( () => {
			xn.tl.tracklistmodel.add_tracks(job.track_dat, true);
			job.track_dat = null;
			return false;
		});
	}
	
	private void get_mediadata_of_hierarchical(ref TrackData[] mda, Gtk.TreePath treepath) {
		TreeIter iter, iterChild;
		TrackData[] mda_local = {};//mda;
		if(treepath.get_depth() ==1)
			return;
		switch(treepath.get_depth()) {
			case 1: //ARTIST (this case is currently not used)
				break;
			case 2: //ALBUM
				this.get_iter(out iter, treepath);

				for(int i = 0; i < this.iter_n_children(iter); i++) { // for each track
					this.iter_nth_child(out iterChild, iter, i);
					bool visible = false;
					TrackData md = new TrackData();
					md.db_id = -1;
					
					this.get(iterChild,
							 Column.VIS_TEXT,  ref md.name,
							 Column.DB_ID,     ref md.db_id,
							 Column.MEDIATYPE, ref md.mediatype,
							 Column.VISIBLE, ref visible
							 );
					if(md.db_id < 0 || !visible)
						continue;
					mda_local += md;
				}
				break;
			case 3: //TITLE
				this.get_iter(out iter, treepath);
				
				TrackData md = new TrackData();
				md.db_id = -1;
				
				this.get(iter,
						 Column.VIS_TEXT,  ref md.name,
						 Column.DB_ID,     ref md.db_id,
						 Column.MEDIATYPE, ref md.mediatype
						 );
				if(md.db_id < 0)
					return;
				
				mda_local += md;
				break;
			default: break;
		}
		mda = mda_local;
	}

	public void queue_path_for_tracklist(Gtk.TreePath treepath) {
		handle_queue_path_for_tracklist(treepath);
	}
	
	private void handle_queue_path_for_tracklist(Gtk.TreePath treepath) {
		TreeIter iter;
		CollectionType br_ct = CollectionType.UNKNOWN;
		this.get_iter(out iter, treepath);
		this.get(iter, Column.COLL_TYPE, ref br_ct);
		if(br_ct == CollectionType.LISTED) {
			var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.queue_listed_data_job);
			job.track_dat = {};
			get_mediadata_of_listed(ref job.track_dat, treepath);
			worker.push_job(job);
		}
		else if(br_ct == CollectionType.HIERARCHICAL) {
			var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.queue_hierarchical_data_job);
			job.track_dat = {};
			get_mediadata_of_hierarchical(ref job.track_dat, treepath);
			worker.push_job(job);
		}
	}

	//TODO: How to do this for videos/streams?
	public DndData[] get_dnd_data_for_path(ref TreePath treepath) {
		TreeIter iter, iterChild, iterChildChild;
		DndData[] dnd_data_array = {};
		ItemType mtype = ItemType.UNKNOWN;
		int dbid = -1;
		//string uri;
		CollectionType br_ct = CollectionType.UNKNOWN;
		bool visible = false;
		this.get_iter(out iter, treepath);
		switch(treepath.get_depth()) {
			case 1:
				this.get(iter, Column.COLL_TYPE, ref br_ct);
				if(br_ct == CollectionType.LISTED) {
					dbid = -1;
					for(int i = 0; i < this.iter_n_children(iter); i++) {
						dbid = -1;
						this.iter_nth_child(out iterChild, iter, i);
						this.get(iterChild,
						         Column.DB_ID, ref dbid,
						         Column.VISIBLE, ref visible,
						         Column.MEDIATYPE, ref mtype
						         );
						if(visible) {
							DndData dnd_data = { dbid, (ItemType)mtype };
							dnd_data_array += dnd_data;
						}
//						if(dbid==-1) break;
//						switch(mtype) {
//							case ItemType.VIDEO: {
//								if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
//								break;
//							}
//							case ItemType.STREAM : {
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
							         Column.VISIBLE, ref visible,
							         Column.MEDIATYPE, ref mtype
							         );
							if(dbid != -1 && visible) {
								DndData dnd_data = { dbid, (ItemType)mtype };
								dnd_data_array += dnd_data;
//								urilist += dbid;
							}
						}
					}
				}
				break;
			case 2:
//				this.get_iter(out iter, treepath);
				this.get(iter, Column.COLL_TYPE, ref br_ct);
				if(br_ct == CollectionType.LISTED) {
					dbid = -1;
					mtype = ItemType.UNKNOWN;
					this.get(iter,
					         Column.DB_ID, ref dbid,
					         Column.VISIBLE, ref visible,
					         Column.MEDIATYPE, ref mtype
					         );
					if(dbid==-1) break;
					
					if(visible) {
						DndData dnd_data = { dbid, (ItemType)mtype };
						dnd_data_array += dnd_data;
//						urilist += dbid;
					}
					
//						switch(mtype) {
//						case ItemType.VIDEO: {
//							//print("is VIDEO\n");
//							if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
//							break;
//						}
//						case ItemType.STREAM : {
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
						this.get(iterChild, 
						         Column.DB_ID, ref dbid,
						         Column.VISIBLE, ref visible,
						         Column.MEDIATYPE, ref mtype
						         );
							if(dbid != -1 && visible) {
								DndData dnd_data = { dbid, (ItemType)mtype };
								dnd_data_array += dnd_data;
//								urilist += dbid;
							}
					}
				}
				break;
			case 3: //TITLE
				dbid = -1;
				this.get(iter, Column.DB_ID, ref dbid, Column.MEDIATYPE, ref mtype);
				if(dbid==-1) break;
				if(dbid != -1) {
//					urilist += dbid;
					DndData dnd_data = { dbid, (ItemType)mtype };
					dnd_data_array += dnd_data;
				}
				break;
		}
		return dnd_data_array;
	}
}
