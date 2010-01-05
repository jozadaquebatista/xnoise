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

// The usage of a own model will give the possibility to simplify
// some things in xnoise and make others more effective.

using Gtk;

public class Xnoise.MediaBrowserModel : Gtk.TreeStore, Gtk.TreeModel {

	public enum Column {
		ICON = 0,
		VIS_TEXT,
		DB_ID,
		MEDIATYPE,
		COLL_TYPE,
		DRAW_SEPTR,
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
		typeof(int)         //DRAW SEPARATOR
	};

	public string searchtext = "";
	private Gdk.Pixbuf artist_pixb;
	private Gdk.Pixbuf album_pixb;
	private Gdk.Pixbuf title_pixb;
	private Gdk.Pixbuf video_pixb;
	private Gdk.Pixbuf videos_pixb;
	private Gdk.Pixbuf radios_pixb;

	construct {
		set_pixbufs();
		set_column_types(col_types);
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

	private void prepend_separator() {
		TreeIter iter;
		this.prepend(out iter, null);
		this.set(iter, Column.DRAW_SEPTR, 1, -1);
	}

	private void put_videos_to_model() {
		DbBrowser dbb = new DbBrowser();
		if(!dbb.videos_available()) return;
		TreeIter iter_videos, iter_singlevideo;
		this.prepend(out iter_videos, null);
		this.set(iter_videos,
		         Column.ICON, videos_pixb,
		         Column.VIS_TEXT, "Videos",
		         Column.COLL_TYPE, CollectionType.LISTED,
		         Column.DRAW_SEPTR, 0
		         );
		var tmis = dbb.get_video_data(ref searchtext);
		foreach(weak MediaData tmi in tmis) {
			this.prepend(out iter_singlevideo, iter_videos);
			this.set(iter_singlevideo,
			         Column.ICON, video_pixb,
			         Column.VIS_TEXT, tmi.name,
			         Column.DB_ID, tmi.id,
			         Column.MEDIATYPE , (int) MediaType.VIDEO,
			         Column.COLL_TYPE, CollectionType.LISTED,
			         Column.DRAW_SEPTR, 0
			         );
		}
		tmis = null;
	}

	public bool populate_model() {
		this.put_hierarchical_data_to_model();
		this.put_listed_data_to_model(); // put at last, then it is on top
		return false;
	}

	private void put_streams_to_model() {
		DbBrowser dbb = new DbBrowser();
		if(!dbb.streams_available()) return;

		TreeIter iter_radios, iter_singleradios;
		this.prepend(out iter_radios, null);
		this.set(iter_radios,
		         Column.ICON, radios_pixb,
		         Column.VIS_TEXT, "Streams",
		         Column.COLL_TYPE, CollectionType.LISTED,
		         Column.DRAW_SEPTR, 0
		         );
		var tmis = dbb.get_stream_data(ref searchtext);
		foreach(weak MediaData tmi in tmis) {
			this.prepend(out iter_singleradios, iter_radios);
			this.set(iter_singleradios,
			         Column.ICON,        radios_pixb,
			         Column.VIS_TEXT,    tmi.name,
			         Column.DB_ID,       tmi.id,
			         Column.MEDIATYPE ,  (int)MediaType.STREAM,
			         Column.COLL_TYPE,   CollectionType.LISTED,
			         Column.DRAW_SEPTR,  0
			         );
		}
	}

	private void put_listed_data_to_model() {
		var dbb = new DbBrowser();

		if(dbb.videos_available())
			prepend_separator();

		put_videos_to_model();

		if(dbb.streams_available())
			prepend_separator();

		put_streams_to_model();
	}

	private void put_hierarchical_data_to_model() {
		DbBrowser artists_browser = new DbBrowser();
		DbBrowser albums_browser  = new DbBrowser();
		DbBrowser titles_browser  = new DbBrowser();

		string[] artistArray;
		string[] albumArray;
		string[] titleArray;
		MediaData[] tmis;

		TreeIter iter_artist, iter_album, iter_title;
		artistArray = artists_browser.get_artists(ref searchtext);
		foreach(weak string artist in artistArray) { 	              //ARTISTS
			this.prepend(out iter_artist, null);
			this.set(iter_artist,
			         Column.ICON, artist_pixb,
			         Column.VIS_TEXT, artist,
			         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
			         Column.DRAW_SEPTR, 0);
			albumArray = albums_browser.get_albums(artist, ref searchtext);
			foreach(weak string album in albumArray) { 			    //ALBUMS
				this.prepend(out iter_album, iter_artist);
				this.set(iter_album,
				         Column.ICON, album_pixb,
				         Column.VIS_TEXT, album,
				         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
				         Column.DRAW_SEPTR, 0);
				tmis = titles_browser.get_titles_with_mediatypes_and_ids(artist, album, ref searchtext);
				foreach(weak MediaData tmi in tmis) {	         //TITLES WITH MEDIATYPES
					this.prepend(out iter_title, iter_album);
					if(tmi.mediatype == MediaType.AUDIO) {
						this.set(iter_title,
						         Column.ICON, title_pixb,
						         Column.VIS_TEXT, tmi.name,
						         Column.DB_ID, tmi.id,
						         Column.MEDIATYPE , (int)tmi.mediatype,
						         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
						         Column.DRAW_SEPTR, 0);
					}
					else {
						this.set(iter_title,
						         Column.ICON, video_pixb,
						         Column.VIS_TEXT, tmi.name,
						         Column.DB_ID, tmi.id,
						         Column.MEDIATYPE , (int)tmi.mediatype,
						         Column.COLL_TYPE, CollectionType.HIERARCHICAL,
						         Column.DRAW_SEPTR, 0);
					}
				}
			}
		}
		artistArray = null;
		albumArray  = null;
		titleArray  = null;
	}

	public TrackData[] get_trackdata_listed(Gtk.TreePath treepath) {
		//this is only used for path.get_depth() == 2 !
		DbBrowser dbb;
		int dbid = -1;
		MediaType mtype = MediaType.UNKNOWN;
		TreeIter iter;
		TrackData[] tdata = {};
		this.get_iter(out iter, treepath);
		this.get(iter,
		         Column.DB_ID, ref dbid,
		         Column.MEDIATYPE, ref mtype
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

	public TrackData[] get_trackdata_hierarchical(Gtk.TreePath treepath) {
		TreeIter iter, iterChild;
		int dbid = -1;
		TrackData[] tdata = {};
		switch(treepath.get_depth()) {
			case 1: //ARTIST (this case is currently not used)
				break;
			case 2: //ALBUM
				this.get_iter(out iter, treepath);

				var dbb = new DbBrowser();

				for(int i = 0; i < this.iter_n_children(iter); i++) {
					dbid = -1;
					this.iter_nth_child(out iterChild, iter, i);
					this.get(iterChild, Column.DB_ID, ref dbid);
					if(dbid==-1) continue;
					TrackData td;
					if(dbb.get_trackdata_for_id(dbid, out td)) tdata += td;
				}
				break;
			case 3: //TITLE
				dbid = -1;
				this.get_iter(out iter, treepath);
				this.get(iter, Column.DB_ID, ref dbid);
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
