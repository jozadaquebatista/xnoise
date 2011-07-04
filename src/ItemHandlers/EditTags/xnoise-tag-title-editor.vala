/* xnoise-tag-title-editor.vala
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
using Xnoise.TagAccess;


public class Xnoise.TagTitleEditor : GLib.Object {
	private unowned Xnoise.Main xn;	
	private Dialog dialog;
	private Gtk.Builder builder;
	private unowned MediaBrowserModel mbm = null;
	
	private Entry entry_artist;
	private Entry entry_album;
	private Entry entry_title;
//	private unowned TreeRowReference treerowref;
	private Item? item;
	
	public signal void sign_finish();

	public TagTitleEditor(Item _item) {
		item = _item;
		xn = Main.instance;
		builder = new Gtk.Builder();
		create_widgets();
		mbm = main_window.mediaBr.mediabrowsermodel;
		fill_entries();
		dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
		dialog.show_all();
	}
	
	private void fill_entries() {
		// read tags and put them to the entries; store current tags to be able to realize changes
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.query_trackdata_job);
		job.item = item;
		db_worker.push_job(job);
	}

	private TrackData td_old = null;
	
	private bool query_trackdata_job(Worker.Job job) {
		// callback for query in other thread
		TrackData[] tmp = {};
//		TrackData[] tda = {};
		tmp = item_converter.to_trackdata(item, ref main_window.mediaBr.mediabrowsermodel.searchtext);
		if(tmp == null && tmp[0] != null)
			return false;
		
		TrackData td = tmp[0];
		
		td_old = copy_trackdata(td);
		
		Idle.add( () => { // TODO more kinds of data
			// put data to entry
			entry_artist.text = td.artist;
			entry_album.text  = td.album;
			entry_title.text  = td.title;
			return false;
		});
		return false;
	}
	
	private Label infolabel;
	private void create_widgets() {
		try {
			dialog = new Dialog();
			
			dialog.set_modal(true);
			dialog.set_transient_for(main_window);
			
			builder.add_from_file(Config.UIDIR + "metadat_title.ui");
			
			var mainvbox           = builder.get_object("vbox1")        as Gtk.VBox;
			var okbutton           = builder.get_object("okbutton")     as Gtk.Button;
			var cancelbutton       = builder.get_object("cancelbutton") as Gtk.Button;
			entry_artist           = builder.get_object("entry_artist") as Gtk.Entry;
			entry_album            = builder.get_object("entry_album")  as Gtk.Entry;
			entry_title            = builder.get_object("entry_title")  as Gtk.Entry;
			infolabel              = builder.get_object("label5")       as Gtk.Label;
		
			((Gtk.VBox)this.dialog.get_content_area()).add(mainvbox);
			okbutton.clicked.connect(on_ok_button_clicked);
			cancelbutton.clicked.connect(on_cancel_button_clicked);
			
			this.dialog.set_default_icon_name("xnoise");
			this.dialog.set_title(_("xnoise - Edit metadata"));
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
	
	private void on_ok_button_clicked(Gtk.Button sender) {
		if(mbm.populating_model) {
			infolabel.label = _("Please wait while filling media browser. Or cancel, if you do not want to wait.");
			return;
		}
		if(global.media_import_in_progress) {
			infolabel.label = _("Please wait while importing media. Or cancel, if you do not want to wait.");
			return;
		}

		if(td_old == null)
			return;
		
		infolabel.label = "";
		TrackData td_new = copy_trackdata(td_old);
		if(entry_artist.text != null && entry_artist.text._strip() != "")
			td_new.artist = entry_artist.text;
		if(entry_album.text != null && entry_album.text._strip() != "")
			td_new.album  = entry_album.text;
		if(entry_title.text != null && entry_title.text._strip() != "")
			td_new.title  = entry_title.text;
		// TODO: UTF-8 validation
		do_track_rename(td_old, td_new);
		Idle.add( () => {
			this.dialog.destroy();
			return false;
		});
	}
	
	private void do_track_rename(TrackData td_old, TrackData td_new) {
		var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_tag_job);
		TrackData[] tda = new TrackData[2];
		tda[0] = td_old;
		tda[1] = td_new;
		job.track_dat = tda;
		db_worker.push_job(job);
	}
	
	// job to update tag in files
	private bool update_tag_job(Worker.Job tag_job) {
		if(tag_job.track_dat[0].item.type == ItemType.LOCAL_AUDIO_TRACK ||
		   tag_job.track_dat[0].item.type == ItemType.LOCAL_VIDEO_TRACK) {
			var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_filetags_job);
			job.track_dat = tag_job.track_dat;
			io_worker.push_job(job);
		}
		return false;
	}
	
	private bool update_filetags_job(Worker.Job job) {
		File f = File.new_for_uri(job.track_dat[1].item.uri);
		var tw = new TagWriter();
		bool ret = false;
		//print("%s\n", job.item.type.to_string());
		ret = tw.write_tag(f, job.track_dat[1]);
		if(ret) {
			var dbjob = new Worker.Job(Worker.ExecutionType.ONCE, this.update_db_job);
			dbjob.track_dat = job.track_dat;
			dbjob.item = job.track_dat[0].item;
			db_worker.push_job(dbjob);
		}
		var fin_job = new Worker.Job(Worker.ExecutionType.ONCE, this.finish_job);
		
		db_worker.push_job(fin_job);
		return false;
	}
	
	private bool update_db_job(Worker.Job job) {
		media_importer.update_item_tag(ref job.item, ref job.track_dat[1]);
		return false;
	}

	private bool finish_job(Worker.Job job) {
		Timeout.add(200, () => {
			main_window.mediaBr.mediabrowsermodel.filter();
			return false;
		});
		Timeout.add(300, () => {
			this.sign_finish();
			return false;
		});
		return false;
	}

	private void on_cancel_button_clicked(Gtk.Button sender) {
		Idle.add( () => {
			this.dialog.destroy();
			this.sign_finish();
			return false;
		});
	}
}

