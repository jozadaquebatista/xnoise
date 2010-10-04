/* xnoise-media-browser-filtermodel.vala
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

public class Xnoise.MediaBrowserFilterModel : Gtk.TreeModelFilter, Gtk.TreeModel {

//	public enum Column {
//		ICON = 0,
//		VIS_TEXT,
//		DB_ID,
//		MEDIATYPE,
//		COLL_TYPE,
//		DRAW_SEPTR,
//		N_COLUMNS
//	}

	public MediaBrowserFilterModel(MediaBrowserModel mbm) {
		GLib.Object(child_model:mbm);
		this.set_visible_func(filterfunc);
	}
	
	private string _searchtext = "";
	public string searchtext { 
		get {
			return _searchtext;
		}
		set {
			_searchtext = value;
		}
	}
	
	private bool filterfunc(Gtk.TreeModel model, Gtk.TreeIter iter) {
		TreePath p = model.get_path(iter);
		switch(p.get_depth()) {
			case 1: //ARTIST
				string artist = null;
				model.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref artist);
				if(artist != null && artist.down().str(_searchtext) != null) {
//					Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
					return true;
				}
				TreeIter iterChild;
				for(int i = 0; i < model.iter_n_children(iter); i++) {
					model.iter_nth_child(out iterChild, iter, i);
					string album = null;
					model.get(iterChild, MediaBrowserModel.Column.VIS_TEXT, ref album);
					if(album != null && album.down().str(_searchtext) != null) {
//						Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
						return true;
					}
					TreeIter iterChildChild;
					for(int j = 0; j < model.iter_n_children(iterChild); j++) {
						model.iter_nth_child(out iterChildChild, iterChild, j);
						string title = null;
						model.get(iterChildChild, MediaBrowserModel.Column.VIS_TEXT, ref title);
						if(title != null && title.down().str(_searchtext) != null) {
//							Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
							return true;
						}
					}
				}
//				Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, false);
				return false;
			case 2: //ALBUM
				string album = null;
				model.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref album);
				if(album != null && album.down().str(_searchtext) != null) {
//					Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
					return true;
				}
				TreeIter iterChild;
				for(int i = 0; i < model.iter_n_children(iter); i++) {
					model.iter_nth_child(out iterChild, iter, i);
					string title = null;
					model.get(iterChild, MediaBrowserModel.Column.VIS_TEXT, ref title);
					if(title != null && title.down().str(_searchtext) != null) {
//						Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
						return true;
					}
				}
				TreeIter iter_parent;
				string artist = null;
				if(model.iter_parent(out iter_parent, iter)) {
					model.get(iter_parent, MediaBrowserModel.Column.VIS_TEXT, ref artist);
					if(artist != null && artist.down().str(_searchtext) != null) {
//						Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
						return true;
					}
				}
				return false;
			case 3: //TITLE
				string title = null;
				model.get(iter, MediaBrowserModel.Column.VIS_TEXT, ref title);
				if(title != null && title.down().str(_searchtext) != null) {
//					Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
					return true;
				}
				TreeIter iter_parent;
				string album = null;
				if(model.iter_parent(out iter_parent, iter)) {
					model.get(iter_parent, MediaBrowserModel.Column.VIS_TEXT, ref album);
					if(album != null && album.down().str(_searchtext) != null) {
//						Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
						return true;
					}
					TreeIter iter_parent_parent;
					string artist = null;
					if(model.iter_parent(out iter_parent_parent, iter_parent)) {
						model.get(iter_parent_parent, MediaBrowserModel.Column.VIS_TEXT, ref artist);
						if(artist != null && artist.down().str(_searchtext) != null) {
//							Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, true);
							return true;
						}
					}
				}
//				Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, false);
				return false;
			default:
//				Xnoise.Main.instance.main_window.mediaBr.mediabrowsermodel.set(iter, MediaBrowserModel.Column.IS_VISIBLE, false);
				return false;
		}
	}
}

