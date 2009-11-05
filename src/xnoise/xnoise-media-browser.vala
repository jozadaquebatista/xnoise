/* xnoise-media-browser.vala
 *
 * Copyright (C) 2009  Jörn Magens
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
using Gdk;

public class Xnoise.MediaBrowser : TreeView, IParams {
	public TreeStore treemodel;
	private TreeStore dummymodel;
	private Main xn;
	private Gdk.Pixbuf artist_pixb;
	private Gdk.Pixbuf album_pixb;
	private Gdk.Pixbuf title_pixb;
	private Gdk.Pixbuf video_pixb;
	private Gdk.Pixbuf videos_pixb;
	private Gdk.Pixbuf radios_pixb;
	private bool dragging;
	private bool use_treelines;
    private string searchtext = "";
	internal int fontsizeMB = 8;
	public signal void sign_activated();
	private const TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};// This is not a very long list but uris are so universal

	public MediaBrowser(ref weak Main xn) {
		this.xn = xn;
		par.iparams_register(this);
		create_model();
		set_pixbufs();
		create_view();
		Idle.add(populate_model);
		this.get_selection().set_mode(SelectionMode.MULTIPLE);		

		Gtk.drag_source_set(
			this,
			Gdk.ModifierType.BUTTON1_MASK, 
			this.target_list,
			Gdk.DragAction.COPY|
			Gdk.DragAction.MOVE);

		this.dragging = false;
		
		this.row_activated        += this.on_row_activated; 
		this.drag_begin           += this.on_drag_begin;
		this.drag_data_get        += this.on_drag_data_get;
		this.drag_end             += this.on_drag_end;
		this.button_release_event += this.on_button_release;
		this.button_press_event   += this.on_button_press;
		this.key_release_event    += this.on_key_released;
	}
	
	// IParams functions
	public void read_params_data() {
		this.fontsizeMB = par.get_int_value("fontsizeMB");
	}

	public void write_params_data() {
		if(this.use_treelines) {
			par.set_int_value("use_treelines", 1);
		}
		else {
			par.set_int_value("use_treelines", 0);
		}
		par.set_int_value("fontsizeMB", fontsizeMB);
	}
	// end IParams functions


	private const int KEY_CURSOR_RIGHT = 0xFF53;
	private const int KEY_CURSOR_LEFT  = 0xFF51;
	private bool on_key_released(MediaBrowser sender, Gdk.EventKey e) {
//		print("%d\n",(int)e.keyval);
		Gtk.TreeModel m;
		switch(e.keyval) {
			case KEY_CURSOR_RIGHT:
				Gtk.TreeSelection selection = this.get_selection();
				if(selection.count_selected_rows()<1) break;
				GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
				TreePath? treepath = selected_rows.nth_data(0);
				if(treepath.get_depth()>2) break;
				if(treepath!=null) this.expand_row(treepath, false);
				break;
			case KEY_CURSOR_LEFT:
				Gtk.TreeSelection selection = this.get_selection();
				if(selection.count_selected_rows()<1) break;
				GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
				TreePath? treepath = selected_rows.nth_data(0);
				if(treepath.get_depth()>2) break;
				if(treepath!=null) this.collapse_row(treepath);
				break;				
			default:
				break;				
		}
		return false; 
	}
	
    public void on_searchtext_changed(Gtk.Entry sender) { 
    	this.searchtext = sender.get_text().down();
    	change_model_data();
    	if((this.searchtext!="")&&
    	   (this.searchtext!=null)) {
			this.expand_all();
    	}
    }

	public bool on_button_press(MediaBrowser sender, Gdk.EventButton e) {
		Gtk.TreePath treepath = null;
		Gtk.TreeViewColumn column;        
		Gtk.TreeSelection selection = this.get_selection();
		int x = (int)e.x; 
		int y = (int)e.y;
		int cell_x, cell_y;

		if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y)) 
			return true;
		
		switch(e.button) {
			case 1: {
				if(selection.count_selected_rows()<= 1) { 
					return false;
				}
				else {
					if(selection.path_is_selected(treepath)) {
						if(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
						   ((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK)) {
							selection.unselect_path(treepath);
						} 
						return true;
					}
					else if(!(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
							((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK))) {
						return true; 
					}
					return false;
				}
			}
			case 3: {
				print("button 3\n"); //TODO
				return false; //TODO check if this is right
			}
		}
		if(!(selection.count_selected_rows()>0 )) 
			selection.select_path(treepath);
		return false; 
	}


	public bool on_button_release(MediaBrowser sender, Gdk.EventButton e) {
		Gtk.TreePath treepath;
		Gtk.TreeViewColumn column;
		int cell_x, cell_y;

		if((e.button != 1)|(this.dragging)) {
			this.dragging = false;
			return true;
		}
		if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
			((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
			return true;
		}

		Gtk.TreeSelection selection = this.get_selection();
		int x = (int)e.x; 
		int y = (int)e.y;
		if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y)) return false;
		selection.unselect_all();
		selection.select_path(treepath);

		return false; 
	}

	private void on_drag_begin(MediaBrowser sender, DragContext context) {
		this.dragging = true;
		Gdk.drag_abort(context, Gtk.get_current_event_time());
		Gtk.TreeSelection selection = this.get_selection();
		if(selection.count_selected_rows() > 1) {
			Gtk.drag_source_set_icon_stock(this, Gtk.STOCK_DND_MULTIPLE);
		}
		else {
			Gtk.drag_source_set_icon_stock(this, Gtk.STOCK_DND);
		}
		return;
	}

	public void on_drag_data_get(MediaBrowser sender, Gdk.DragContext context, Gtk.SelectionData selection, uint info, uint etime) {
		string[] uris = {};
		List<weak TreePath> treepaths;
		weak Gtk.TreeSelection sel;
		sel = this.get_selection();
		treepaths = sel.get_selected_rows(null);
		foreach(weak TreePath treepath in treepaths) {
			string[] l = this.build_uri_list_for_treepath(treepath);
			foreach(weak string u in l) {
				uris += u;
			}
		}
		uris += null;
		selection.set_uris(uris);
	}

	private string[] build_uri_list_for_treepath(Gtk.TreePath treepath) {
		TreeIter iter, iterChild, iterChildChild; 
		string[] urilist = {};
		DbBrowser dbb;
		MediaType mtype = MediaType.UNKNOWN;
		int dbid = -1;
		string uri;
		BrowserCollectionType br_ct = BrowserCollectionType.UNKNOWN;
		switch(treepath.get_depth()) {
			case 1:
				treemodel.get_iter(out iter, treepath);
				dbb = new DbBrowser();

				treemodel.get(iter, BrowserColumn.COLL_TYPE, ref br_ct);
				if(br_ct == BrowserCollectionType.LISTED) {
					dbid = -1;
					for(int i = 0; i < treemodel.iter_n_children(iter); i++) {
						dbid = -1;
						treemodel.iter_nth_child(out iterChild, iter, i);
						treemodel.get(iterChild, 
						              BrowserColumn.DB_ID, ref dbid,
						              BrowserColumn.MEDIATYPE, ref mtype
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
				else if(br_ct == BrowserCollectionType.HIERARCHICAL) {
					for(int i = 0; i < treemodel.iter_n_children(iter); i++) {
						treemodel.iter_nth_child(out iterChild, iter, i);
						for(int j = 0; j<treemodel.iter_n_children(iterChild); j++) {
							dbid = -1;
							treemodel.iter_nth_child(out iterChildChild, iterChild, j);
							treemodel.get(iterChildChild, BrowserColumn.DB_ID, ref dbid);
							if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
						}
					}
				}
				break;
			case 2:
				treemodel.get_iter(out iter, treepath);
				dbb = new DbBrowser();
				treemodel.get(iter, BrowserColumn.COLL_TYPE, ref br_ct);
				if(br_ct == BrowserCollectionType.LISTED) {
					dbid = -1;
					mtype = MediaType.UNKNOWN;
					treemodel.get(iter, 
					              BrowserColumn.DB_ID, ref dbid,
					              BrowserColumn.MEDIATYPE, ref mtype
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
				else if(br_ct == BrowserCollectionType.HIERARCHICAL) {
					
					for(int i = 0; i < treemodel.iter_n_children(iter); i++) {
						dbid = -1;
						treemodel.iter_nth_child(out iterChild, iter, i);
						treemodel.get(iterChild, BrowserColumn.DB_ID, ref dbid);
						if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
					}
				}
				break;
			case 3: //TITLE
				dbid = -1;
				treemodel.get_iter(out iter, treepath);
				treemodel.get(iter, BrowserColumn.DB_ID, ref dbid);
				if(dbid==-1) break;
				dbb = new DbBrowser();
				if(dbb.get_uri_for_id(dbid, out uri)) urilist += uri;
				break;
		}
		return urilist;		
	}

	private TrackData[] get_trackdata_listed(Gtk.TreePath treepath) {
		//this is only used for path.get_depth() == 2 !
		DbBrowser dbb;
		int dbid = -1;
		MediaType mtype = MediaType.UNKNOWN;
		TreeIter iter;
		TrackData[] tdata = {}; 
		treemodel.get_iter(out iter, treepath);
		treemodel.get(iter, 
		              BrowserColumn.DB_ID, ref dbid,
		              BrowserColumn.MEDIATYPE, ref mtype
		              );
		if(dbid!=-1) {
			dbb = new DbBrowser();
			TrackData td;
			switch(mtype) {
				case MediaType.VIDEO: {
					if(dbb.get_trackdata_for_id(dbid, out td)) tdata += td;
					break;
				}
				case MediaType.STREAM : {
					if(dbb.get_stream_td_for_id(dbid, out td)) tdata += td;
					break;
				}
				default:
					break;
			}
		} 

		return tdata;
	}
	
	private TrackData[] get_trackdata_hierarchical(Gtk.TreePath treepath) {
		TreeIter iter, iterChild;
		int dbid = -1;
		TrackData[] tdata = {}; 
		switch(treepath.get_depth()) {
			case 1: //ARTIST (this case is currently not used)
				break;
			case 2: //ALBUM
				treemodel.get_iter(out iter, treepath);
				
				var dbb = new DbBrowser();
				
				for(int i = 0; i < treemodel.iter_n_children(iter); i++) {
					dbid = -1;
					treemodel.iter_nth_child(out iterChild, iter, i);
					treemodel.get(iterChild, BrowserColumn.DB_ID, ref dbid);
					if(dbid==-1) continue;
					TrackData td;
					if(dbb.get_trackdata_for_id(dbid, out td)) tdata += td;
				}
				break;
			case 3: //TITLE
				dbid = -1;
				treemodel.get_iter(out iter, treepath);
				treemodel.get(iter, BrowserColumn.DB_ID, ref dbid);
				if(dbid==-1) break;
				
				var dbb = new DbBrowser();
				
				TrackData td;
				if(dbb.get_trackdata_for_id(dbid, out td)) tdata += td;
				break;
		}		
		return tdata;
	}
	
	public TrackData[] get_trackdata_for_treepath(Gtk.TreePath treepath) {
		TreeIter iter;
		BrowserCollectionType br_ct = BrowserCollectionType.UNKNOWN;
		TrackData[] tdata = {}; 
		treemodel.get_iter(out iter, treepath);
		treemodel.get(iter, BrowserColumn.COLL_TYPE, ref br_ct);
		if(br_ct == BrowserCollectionType.LISTED) {
			return get_trackdata_listed(treepath);
		}
		else if(br_ct == BrowserCollectionType.HIERARCHICAL) {
			return get_trackdata_hierarchical(treepath);
		}
		return tdata;
	}

	public void on_drag_end(MediaBrowser sender, Gdk.DragContext context) { 
		this.dragging = false;
		this.unset_rows_drag_dest();
		Gtk.drag_dest_set( 
			this,
			Gtk.DestDefaults.ALL,
			this.target_list, 
			Gdk.DragAction.COPY|
			Gdk.DragAction.MOVE);
	}

	private void on_row_activated(MediaBrowser sender, TreePath treepath, TreeViewColumn column){
		if(treepath.get_depth()>1) {
			TrackData[] td_list = this.get_trackdata_for_treepath(treepath);
			this.add_songs_to_tracklist(td_list, true);
			td_list = null;
		}
		else {
			this.expand_row(treepath, false);
		}
	}

	private void add_songs_to_tracklist(TrackData[] td_list, bool imediate_play = false)	{
		int i = 0;
		TreeIter iter;
		TreeIter iter_2 = TreeIter();
		if(imediate_play) xn.main_window.trackList.reset_play_status_all_titles();
		foreach(TrackData td in td_list) {
			string uri = td.Uri; 
			int tracknumber = (int)td.Tracknumber;
			if(imediate_play) {
				if(i==0) {
					iter = xn.main_window.trackList.insert_title(
					           TrackState.PLAYING, 
					           null, 
					           tracknumber,
					           Markup.printf_escaped("%s", td.Title), 
					           Markup.printf_escaped("%s", td.Album), 
					           Markup.printf_escaped("%s", td.Artist), 
					           uri
					       );
					xn.main_window.trackList.set_state_picture_for_title(iter, TrackState.PLAYING);
					iter_2 = iter;
				}
				else {
					iter = xn.main_window.trackList.insert_title(
					           TrackState.STOPPED, 
					           null, 
					           tracknumber,
					           Markup.printf_escaped("%s", td.Title), 
					           Markup.printf_escaped("%s", td.Album), 
					           Markup.printf_escaped("%s", td.Artist), 
					           uri
					       );			
				}
				i++;
			}
			else {
				iter = xn.main_window.trackList.insert_title(
				           TrackState.STOPPED, 
				           null, 
				           tracknumber,
				           Markup.printf_escaped("%s", td.Title), 
				           Markup.printf_escaped("%s", td.Album), 
				           Markup.printf_escaped("%s", td.Artist), 
				           uri
				       );			
			}
		}
		if(imediate_play) xn.main_window.trackList.set_focus_on_iter(ref iter_2);		
	}

	public bool change_model_data() {
		dummymodel = new TreeStore(BrowserColumn.N_COLUMNS,
		                           typeof(Gdk.Pixbuf), //ICON
		                           typeof(string),     //VIS_TEXT
		                           typeof(int),        //DB_ID
		                           typeof(int),        //MEDIATYPE
		                           typeof(int),        //COLL_TYPE
		                           typeof(int)         //DRAW SEPARATOR
		                           );
		set_model(dummymodel);
		treemodel.clear();
		populate_model();
		xn.main_window.searchEntryMB.set_sensitive(true);
		this.set_sensitive(true);
		return false;
	}

	private void create_model() {	// DATA
		treemodel = new TreeStore(BrowserColumn.N_COLUMNS,
		                          typeof(Gdk.Pixbuf), //ICON
		                          typeof(string),     //VIS_TEXT
		                          typeof(int),        //DB_ID
		                          typeof(int),        //MEDIATYPE
		                          typeof(int),        //COLL_TYPE
		                          typeof(int)         //DRAW SEPARATOR
		                          );
	}

	// Puts data to treemodel and sets view to treemodel
	// Can be used with Idle
	private bool populate_model() {
		put_hierarchical_data_to_model();
		put_listed_data_to_model(); // put at last, then it is on top
		set_model(treemodel);
		return false;
	}
	
	private void prepend_separator() {
		TreeIter iter;
		treemodel.prepend(out iter, null); 
		treemodel.set(iter, BrowserColumn.DRAW_SEPTR, 1, -1); 
	}
	
	private void put_listed_data_to_model() {
		var dbb = new DbBrowser();
		if(dbb.videos_available()) prepend_separator(); // TODO: only prepend if data is available
		put_videos_to_model();
		if(dbb.streams_available()) prepend_separator();
		put_streams_to_model();
	}
			
	private void put_hierarchical_data_to_model() {
		DbBrowser artists_browser = new DbBrowser();
		DbBrowser albums_browser  = new DbBrowser();
		DbBrowser titles_browser  = new DbBrowser();

		string[] artistArray;
		string[] albumArray;
		string[] titleArray;
		TitleMtypeId[] tmis;
		
		TreeIter iter_artist, iter_album, iter_title;	
		artistArray = artists_browser.get_artists(ref searchtext);
		foreach(weak string artist in artistArray) { 	              //ARTISTS
			treemodel.prepend(out iter_artist, null); 
			treemodel.set(iter_artist,  	
				BrowserColumn.ICON, artist_pixb,		
				BrowserColumn.VIS_TEXT, artist,
				BrowserColumn.COLL_TYPE, BrowserCollectionType.HIERARCHICAL,
				BrowserColumn.DRAW_SEPTR, 0,
				-1); 
			albumArray = albums_browser.get_albums(artist, ref searchtext);
			foreach(weak string album in albumArray) { 			    //ALBUMS
				treemodel.prepend(out iter_album, iter_artist); 
				treemodel.set(iter_album,  	
					BrowserColumn.ICON, album_pixb,		
					BrowserColumn.VIS_TEXT, album,
					BrowserColumn.COLL_TYPE, BrowserCollectionType.HIERARCHICAL,
					BrowserColumn.DRAW_SEPTR, 0,	
					-1); 
				tmis = titles_browser.get_titles_with_mediatypes_and_ids(artist, album, ref searchtext);
				foreach(weak TitleMtypeId tmi in tmis) {	         //TITLES WITH MEDIATYPES
					treemodel.prepend(out iter_title, iter_album); 
					if(tmi.mediatype == MediaType.AUDIO) {
						treemodel.set(iter_title,  	
							BrowserColumn.ICON, title_pixb,		
							BrowserColumn.VIS_TEXT, tmi.name,
							BrowserColumn.DB_ID, tmi.id,
							BrowserColumn.MEDIATYPE , (int)tmi.mediatype,
							BrowserColumn.COLL_TYPE, BrowserCollectionType.HIERARCHICAL,
							BrowserColumn.DRAW_SEPTR, 0,
							-1); 
					}
					else {
						treemodel.set(iter_title,  	
							BrowserColumn.ICON, video_pixb,		
							BrowserColumn.VIS_TEXT, tmi.name,
							BrowserColumn.DB_ID, tmi.id,
							BrowserColumn.MEDIATYPE , (int)tmi.mediatype,
							BrowserColumn.COLL_TYPE, BrowserCollectionType.HIERARCHICAL,
							BrowserColumn.DRAW_SEPTR, 0,
							-1); 						
					}
				}
			}
		}
		artistArray = null;
		albumArray = null;
		titleArray = null;
	}

	private void put_streams_to_model() {
		DbBrowser dbb = new DbBrowser();
		if(!dbb.streams_available()) return;
		
		TreeIter iter_radios, iter_singleradios;
		treemodel.prepend(out iter_radios, null); 
		treemodel.set(iter_radios,  	
		              BrowserColumn.ICON, radios_pixb,
		              BrowserColumn.VIS_TEXT, "Streams",
		              BrowserColumn.COLL_TYPE, BrowserCollectionType.LISTED,
		              BrowserColumn.DRAW_SEPTR, 0,
		              -1
		              );
		var tmis = dbb.get_stream_data(ref searchtext);
		foreach(weak TitleMtypeId tmi in tmis) {
			treemodel.prepend(out iter_singleradios, iter_radios); 
			treemodel.set(iter_singleradios,  	
			              BrowserColumn.ICON,        radios_pixb,
			              BrowserColumn.VIS_TEXT,    tmi.name,
			              BrowserColumn.DB_ID,       tmi.id,
			              BrowserColumn.MEDIATYPE ,  (int)MediaType.STREAM,
			              BrowserColumn.COLL_TYPE,   BrowserCollectionType.LISTED,
			              BrowserColumn.DRAW_SEPTR,  0,
			              -1
			              ); 
		}
	}

	private void put_videos_to_model() {
		DbBrowser dbb = new DbBrowser();
		if(!dbb.videos_available()) return;
		TreeIter iter_videos, iter_singlevideo;
		treemodel.prepend(out iter_videos, null); 
		treemodel.set(iter_videos,  	
		              BrowserColumn.ICON, videos_pixb,
		              BrowserColumn.VIS_TEXT, "Videos",
		              BrowserColumn.COLL_TYPE, BrowserCollectionType.LISTED,
		              BrowserColumn.DRAW_SEPTR, 0,
		              -1
		              ); 
		var tmis = dbb.get_video_data(ref searchtext);
		foreach(weak TitleMtypeId tmi in tmis) {
			treemodel.prepend(out iter_singlevideo, iter_videos); 
			treemodel.set(iter_singlevideo,  	
			              BrowserColumn.ICON, video_pixb,
			              BrowserColumn.VIS_TEXT, tmi.name,
			              BrowserColumn.DB_ID, tmi.id,
			              BrowserColumn.MEDIATYPE , (int) MediaType.VIDEO,
			              BrowserColumn.COLL_TYPE, BrowserCollectionType.LISTED,
			              BrowserColumn.DRAW_SEPTR, 0,
			              -1
			              ); 
		}
		tmis = null;
	}
		
	private void set_pixbufs() {
		try {
			artist_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "guitar.png");
			album_pixb  = new Gdk.Pixbuf.from_file(Config.UIDIR + "album.png");
			title_pixb  = new Gdk.Pixbuf.from_file(Config.UIDIR + "note.png");
			Gtk.Invisible w = new Gtk.Invisible();
			videos_pixb  = w.render_icon(Gtk.STOCK_MEDIA_RECORD, IconSize.BUTTON, null);
			radios_pixb  = w.render_icon(Gtk.STOCK_CONNECT, IconSize.BUTTON, null);
			
			w = new Gtk.Invisible();
			video_pixb  = w.render_icon(Gtk.STOCK_FILE, IconSize.BUTTON, null); 
		}
		catch (GLib.Error e) {
			print("Error: %s\n",e.message);
		}
	}	

	private void create_view() {	
		if(fontsizeMB < 7) fontsizeMB = 7;

		this.set_size_request (300,500);
		var renderer = new CellRendererText();
		renderer.font = "Sans " + fontsizeMB.to_string(); 
//		renderer.family = "Sans"; //TODO: Does not work!?
//		renderer.size = 9; //TODO: Does not work!?
		renderer.set_fixed_height_from_font(1);
		var pixbufRenderer = new CellRendererPixbuf();
		pixbufRenderer.stock_id = Gtk.STOCK_GO_FORWARD;
		
		var column = new TreeViewColumn();
		
		column.pack_start(pixbufRenderer, false);
		column.add_attribute(pixbufRenderer, "pixbuf", 0);
		column.pack_start(renderer, false);
		column.add_attribute(renderer, "text", 1); // no markup!!
		this.insert_column(column, -1);

		if(par.get_int_value("use_treelines")==1) 
			use_treelines=true;
		else 
			use_treelines=false;
			
		this.enable_tree_lines = use_treelines;
		this.headers_visible = false;
		this.enable_search = true;
		this.set_row_separator_func((m, iter) => {
			int sepatator = 0;
			m.get(iter, BrowserColumn.DRAW_SEPTR, ref sepatator);
			if(sepatator==0) return false;
			return true;
		});
	}
}

