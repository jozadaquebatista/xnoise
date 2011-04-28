/* xnoise-tag-artistalbum-editor.vala
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

using Gtk;

internal class Xnoise.TagArtistAlbumEditor : GLib.Object {
	private unowned Xnoise.Main xn;	
	private Dialog dialog;
	private Gtk.Builder builder;
	private Content content;
	
	private Entry entry;
	private unowned TreeRowReference treerowref;
	
	private enum Content {
		ARTIST,
		ALBUM
	}
	
	public signal void sign_finish();

	public TagArtistAlbumEditor(ref TreeRowReference _treerowref) {
		if(!_treerowref.valid()) {
			Idle.add( () => {
				sign_finish();
				return false;
			});
			return;
		}
		treerowref = _treerowref;
		TreePath path = null;
		path = treerowref.get_path();
		int depth = path.get_depth();
		switch(depth) {
			case 1:
				content = Content.ARTIST;
				break;
			case 2:
				content = Content.ALBUM;
				break;
			default:
				Idle.add( () => {
					sign_finish();
					return false;
				});
				return;	
		}
		xn = Main.instance;
		builder = new Gtk.Builder();
		create_widgets();
		
		fill_entries();
		dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
		dialog.show_all();
	}
	
	private void fill_entries() {
		TreePath path;
		TreeModel model;
		TreeIter iter;
		string? content_text = null;
		if(treerowref.valid()) {
			model = treerowref.get_model();
			path  = treerowref.get_path();
			
			model.get_iter(out iter, path);
			model.get(iter, MediaBrowserModel.Column.VIS_TEXT, out content_text);
			if(content_text == null)
				content_text = "";
			new_content_name = content_text;
			Idle.add( () => {
				// put data to entry
				entry.text = content_text;
				return false;
			});
			
		}
	}

	private Label infolabel;
	private void create_widgets() {
		try {
			dialog = new Dialog();
			
			dialog.set_modal(true);
			dialog.set_transient_for(xn.main_window);
			
			builder.add_from_file(Config.UIDIR + "metadat_artist_album.ui");
			
			var mainvbox           = builder.get_object("vbox1")           as Gtk.VBox;
			var okbutton           = builder.get_object("okbutton")        as Gtk.Button;
			var cancelbutton       = builder.get_object("cancelbutton")    as Gtk.Button;
			entry                  = builder.get_object("entry1")          as Gtk.Entry;
			infolabel              = builder.get_object("label5")          as Gtk.Label;
			var explainer_label    = builder.get_object("explainer_label") as Gtk.Label;
			var content_label      = builder.get_object("content_label")   as Gtk.Label;
			
			((Gtk.VBox)this.dialog.get_content_area()).add(mainvbox);
			okbutton.clicked.connect(on_ok_button_clicked);
			cancelbutton.clicked.connect(on_cancel_button_clicked);
			
			this.dialog.set_default_icon_name("xnoise");
			this.dialog.set_title(_("xnoise - Edit metadata"));
			switch(content) {
				case Content.ARTIST:
					explainer_label.label = _("Type new artist name.");
					content_label.label = _("Artist:");
					break;
				case Content.ALBUM:
					explainer_label.label = _("Type new album name.");
					content_label.label = _("Album:");
					break;
				default:
					break;	
			}
		}
		catch (GLib.Error e) {
			var msg = new Gtk.MessageDialog(null,
			                                Gtk.DialogFlags.MODAL,
			                                Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.CANCEL,
			                                "Failed to build dialog! %s\n".printf(e.message));
			msg.run();
			return;
		}
	}
	
	private string new_content_name = null;
	private unowned MediaBrowserModel mbm = null;
	
	private void on_ok_button_clicked(Gtk.Button sender) {
		if(!treerowref.valid())
			return; // TODO: user info
		mbm = (MediaBrowserModel)treerowref.get_model();
		if(mbm.populating_model) {
			infolabel.label = _("Please wait while filling media browser. Or cancel, if you do not want to wait.");
			return;
		}
		if(global.media_import_in_progress) {
			infolabel.label = _("Please wait while importing media. Or cancel, if you do not want to wait.");
			return;
		}
		infolabel.label = "";
		if(entry.text != null && entry.text.strip() != "")
			new_content_name = entry.text.strip();
		// TODO: UTF-8 validation
		switch(content) {
			case Content.ARTIST:
				do_artist_rename();
				break;
			case Content.ALBUM:
				do_album_rename();
				break;
			default:
				break;	
		}
		Idle.add( () => {
			this.dialog.destroy();
			this.sign_finish();
			return false;
		});
	}
	
	private void do_artist_rename() {
		if(mbm == null)
			return;
		TreeIter artist_iter, album_iter, title_iter;
		int32[]? ids = {};
		TreePath path  = treerowref.get_path();
		mbm.get_iter(out artist_iter, path);
		mbm.set(artist_iter, MediaBrowserModel.Column.VIS_TEXT, new_content_name);
		for(int i = 0; i < mbm.iter_n_children(artist_iter); i++) {
			mbm.iter_nth_child(out album_iter, artist_iter, i);
			for(int j = 0; j < mbm.iter_n_children(album_iter); j++) {
				mbm.iter_nth_child(out title_iter, album_iter, j);
				int32 id = -1;
				mbm.get(title_iter, MediaBrowserModel.Column.DB_ID, ref id);
				ids += id;
			}
		}
		if(ids.length < 1)
			return;
		Worker.Job artist_job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.update_tags_job);
		artist_job.set_arg("new_content_name", new_content_name);
		artist_job.id_array = ids;
		artist_job.set_arg("treerowref", treerowref);
		artist_job.set_arg("content", (int)this.content);
//		artist_job.finished.connect( () => {
//		});
		worker.push_job(artist_job);		
	}

	private void update_tags_job(Worker.Job tag_job) {
		bool first = true;
		Content ctnt = (Content) ((int)tag_job.get_arg("content"));
		foreach(int32 id in tag_job.id_array) {
			if(ctnt == Content.ARTIST) {
				var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.update_single_artist_tag_job);
				job.set_arg("new_content_name", ((string)tag_job.get_arg("new_content_name")));
				job.set_arg("id", id);
				job.set_arg("first", first);
				if(first)
					first = false;
				worker.push_job(job);
			}
			else if(ctnt == Content.ALBUM) {
				var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.update_single_album_tag_job);
				job.set_arg("new_content_name", ((string)tag_job.get_arg("new_content_name")));
				job.set_arg("id", id);
				job.set_arg("first", first);
				if(first)
					first = false;
				worker.push_job(job);
			}
		}
	}

	private void do_album_rename() {
		if(mbm == null)
			return;
		TreeIter album_iter, title_iter;
		int32[]? ids = {};
		TreePath path  = treerowref.get_path();
		mbm.get_iter(out album_iter, path);
		mbm.set(album_iter, MediaBrowserModel.Column.VIS_TEXT, new_content_name);
		for(int j = 0; j < mbm.iter_n_children(album_iter); j++) {
			mbm.iter_nth_child(out title_iter, album_iter, j);
			int32 id = -1;
			mbm.get(title_iter, MediaBrowserModel.Column.DB_ID, ref id);
			ids += id;
		}
		if(ids.length < 1)
			return;
		Worker.Job album_job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.update_tags_job);
		album_job.set_arg("new_content_name", new_content_name);
		album_job.id_array = ids;
		album_job.set_arg("treerowref", treerowref);
		album_job.set_arg("content", (int)this.content);
//		album_job.finished.connect( () => {
//		});
		worker.push_job(album_job);		
	
	}

	private void update_single_artist_tag_job(Worker.Job job) {
		string text = (string)job.get_arg("new_content_name");
		int32 id = (int32)job.get_arg("id");
		bool first = (bool)job.get_arg("first");
		string? uri = null;
		if(text == null)
			return;
		uri = media_importer.get_uri_for_item_id(id);
		if(uri == null)
			return;
		File f = File.new_for_uri(uri);
		TagWriter tw = new TagWriter();
		bool retval = tw.write_artist(f, text);
		
		if(retval && first) {
			media_importer.update_artist_name(id, ref text);
		}
	}

	private void update_single_album_tag_job(Worker.Job job) {
		string text = (string)job.get_arg("new_content_name");
		int32 id = (int32)job.get_arg("id");
		bool first = (bool)job.get_arg("first");
		string? uri = null;
		if(text == null)
			return;
		uri = media_importer.get_uri_for_item_id(id);
		if(uri == null)
			return;
		File f = File.new_for_uri(uri);
		TagWriter tw = new TagWriter();
		bool retval = tw.write_album(f, text);
		
		if(retval && first) {
			media_importer.update_album_name(id, ref text);
		}
	}

	private void on_cancel_button_clicked(Gtk.Button sender) {
		Idle.add( () => {
			this.dialog.destroy();
			this.sign_finish();
			return false;
		});
	}
}

