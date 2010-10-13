/* xnoise-add-media-dialog.vala
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

public class Xnoise.AddMediaDialog : GLib.Object {

	private const string XNOISEICON = Config.UIDIR + "xnoise_16x16.png";
	private Gtk.Dialog dialog;
	public Gtk.Builder builder;
	private ListStore listmodel;
	private TreeView tv;
	private string[] list_of_folders;
	private string[] list_of_files;
	private string[] list_of_streams;

	private enum MediaStorageType {
		FILE = 0,
		FOLDER,
		STREAM
	}

	public signal void sign_finish();

	public AddMediaDialog() {
		builder = new Gtk.Builder();
		create_widgets();

		fill_media_list();

		this.dialog.show_all();
	}

	//	~AddMediaDialog() {
	//		print("destruct amd\n");
	//	}

	private void fill_media_list() {
		return_if_fail(listmodel!=null);

		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}

		//add folders
		var mfolders = dbb.get_media_folders();
		foreach(string mfolder in mfolders) {
			TreeIter iter;
			listmodel.append(out iter);
			listmodel.set(iter,
			              0, mfolder,
			              1, MediaStorageType.FOLDER,
			              -1
			              );
		}

		//add files
		var mfiles = dbb.get_media_files();
		//print("mfiles length: %d\n", mfiles.length);
		foreach(string uri in mfiles) {
			File file = File.new_for_uri(uri);
			TreeIter iter;
			listmodel.append(out iter);
			listmodel.set(iter,
			              0, file.get_path(),
			              1, MediaStorageType.FILE,
			              -1
			              );
		}

		//add streams to list
		var streams = dbb.get_streams();
		foreach(StreamData sd in streams) {
			TreeIter iter;
			listmodel.append(out iter);
			listmodel.set(iter,
			              0, sd.Uri,
			              1, MediaStorageType.STREAM,
			              -1
			              );
		}
	}

	private void harvest_media_locations() {
		list_of_streams = {};
		list_of_files = {};
		list_of_folders = {};
		listmodel.foreach(list_foreach);
	}

	private void create_widgets() {
		try {
			dialog = new Dialog();

			dialog.set_modal(true);
			builder.add_from_file(Config.UIDIR + "add_media.ui");

			var mainvbox         = builder.get_object("mainvbox") as Gtk.VBox;
			tv                   = builder.get_object("tv") as TreeView;
			var baddfile         = builder.get_object("addfilebutton") as Button;
			var baddfolder       = builder.get_object("addfolderbutton") as Button;
			var baddradio        = builder.get_object("addradiobutton") as Button;
			var brem             = builder.get_object("removeButton") as Button;

			var labeladdfile     = builder.get_object("labeladdfile") as Label;
			var labeladdfolder   = builder.get_object("labeladdfolder") as Label;
			var labeladdstream   = builder.get_object("labeladdstream") as Label;
			var labelremove      = builder.get_object("labelremove") as Label;

			var bcancel          = (Button)this.dialog.add_button(Gtk.STOCK_CANCEL, 0);
			var bok              = (Button)this.dialog.add_button(Gtk.STOCK_OK, 1);

			labeladdfile.label   = _("Add local file");
			labeladdfolder.label = _("Add local folder");
			labeladdstream.label = _("Add media stream");
			labelremove.label    = _("Remove");

			bok.clicked.connect(on_ok_button_clicked);
			bcancel.clicked.connect(on_cancel_button_clicked);
			baddfile.clicked.connect(on_add_file_button_clicked);
			baddfolder.clicked.connect(on_add_folder_button_clicked);
			baddradio.clicked.connect(on_add_radio_button_clicked);
			brem.clicked.connect(on_remove_button_clicked);

			this.dialog.vbox.add(mainvbox);
			this.dialog.set_icon_from_file(XNOISEICON);
			this.dialog.set_title(_("xnoise - Add media to library"));
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

		listmodel = new ListStore(2, typeof(string), typeof(int));
		tv.set_model(listmodel);
		CellRendererText cell = new Gtk.CellRendererText ();
		cell.set("foreground_set", true, null);
		tv.insert_column_with_attributes(-1, "Path", cell, "text", 0);
	}

	private bool list_foreach(TreeModel sender, TreePath mypath, TreeIter myiter) {
		string gv;
		MediaStorageType mst;
		sender.get(myiter,
		           0, out gv,
		           1, out mst
		           );
		switch(mst) {
			case MediaStorageType.FOLDER:
				list_of_folders += gv;
				break;
			case MediaStorageType.FILE:
				var file = File.new_for_path(gv);
				list_of_files += file.get_uri();
				break;
			case MediaStorageType.STREAM:
				list_of_streams += gv;
				break;
			default:
				print("Error: unknown media storage type\n");
				break;
		}
		return false;
	}

	private uint msg_id;
	
	private void on_ok_button_clicked() {
		Main.instance.main_window.mediaBr.mediabrowsermodel.cancel_fill_model();
		Timeout.add(200, () => {
			msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
		                        UserInfo.ContentClass.WAIT,
		                        "Importing media data. This may take some time...",
		                        true,
		                        5,
		                        null);
		
			harvest_media_locations();

			global.media_import_in_progress = true;
			Main.instance.main_window.mediaBr.mediabrowsermodel.clear();

			// global.media_import_in_progress has to be reset in the last job !
			Worker.Job job;
			job = new Worker.Job(1, Worker.ExecutionType.ONE_SHOT, null,  media_importer.store_streams_job);
			job.set_arg("list_of_streams", list_of_streams);
			worker.push_job(job);
			
			job = new Worker.Job(1, Worker.ExecutionType.ONE_SHOT, null,  media_importer.store_files_job);
			job.set_arg("list_of_files", list_of_files);
			worker.push_job(job);
			
			job = new Worker.Job(1, Worker.ExecutionType.ONE_SHOT, null, media_importer.store_folders_job);
			job.set_arg("mfolders", list_of_folders);
			job.set_arg("msg_id", msg_id);
			worker.push_job(job);
			
			this.dialog.destroy();
			this.sign_finish();
			return false;
		});
	}

	private void on_cancel_button_clicked() {
		this.dialog.destroy();
		this.sign_finish();
	}

	private void on_add_file_button_clicked() {
		Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
			_("Select media file"),
			this.dialog,
			Gtk.FileChooserAction.OPEN,
			Gtk.STOCK_CANCEL,
			Gtk.ResponseType.CANCEL,
			Gtk.STOCK_OPEN,
			Gtk.ResponseType.ACCEPT,
			null);
		fcdialog.set_current_folder(Environment.get_home_dir());
		if(fcdialog.run() == Gtk.ResponseType.ACCEPT) {
			TreeIter iter;
			listmodel.append(out iter);
			listmodel.set(iter,
			              0, fcdialog.get_filename(),
			              1, MediaStorageType.FILE,
			              -1
			              );
		}
		fcdialog.destroy();
		fcdialog = null;
	}

	private void on_add_folder_button_clicked() {
		Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
			_("Select media folder"),
			this.dialog,
			Gtk.FileChooserAction.SELECT_FOLDER,
			Gtk.STOCK_CANCEL,
			Gtk.ResponseType.CANCEL,
			Gtk.STOCK_OPEN,
			Gtk.ResponseType.ACCEPT,
			null);
		fcdialog.set_current_folder(Environment.get_home_dir());
		if (fcdialog.run() == Gtk.ResponseType.ACCEPT) {
			TreeIter iter;
			listmodel.append(out iter);
			listmodel.set(iter,
			              0, fcdialog.get_filename(),
			              1, MediaStorageType.FOLDER,
			              -1
			              );
		}
		fcdialog.destroy();
		fcdialog = null;
	}


	private Gtk.Dialog radiodialog;
	private Gtk.Entry radioentry;

	private void on_add_radio_button_clicked() {
		radiodialog = new Gtk.Dialog();
		radiodialog.set_modal(true);
		radiodialog.set_keep_above(true);

		radioentry = new Gtk.Entry();
		radioentry.set_width_chars(50);
		radioentry.secondary_icon_stock = Gtk.STOCK_CLEAR;
		radioentry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
		radioentry.icon_press.connect( (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
			if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = "";
		});
		radiodialog.vbox.pack_start(radioentry, true, true, 0);

		var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.STOCK_CANCEL, 0);
		radiocancelbutton.clicked.connect( () => {
			radiodialog.close();
			radiodialog = null;
		});

		var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.STOCK_OK, 1);
		radiookbutton.clicked.connect( () => {
			if((radioentry.text!=null)&&
			   (radioentry.text.strip()!="")) {
				TreeIter iter;
				listmodel.append(out iter);
				listmodel.set(iter,
					          0, radioentry.text.strip(),
					          1, MediaStorageType.STREAM,
					          -1
					          );
			}

			radiodialog.close();
			radiodialog = null;
		});

		radiodialog.destroy_event.connect( () => {
			radiodialog = null;
			return true;
		});

		try {
			radiodialog.set_icon_from_file(XNOISEICON);
			radiodialog.set_title(_("Add internet radio link"));
		}
		catch(GLib.Error e) {
			var msg = new Gtk.MessageDialog(null,
			                                Gtk.DialogFlags.MODAL,
			                                Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.CANCEL,
			                                "Failed set icon! %s\n".printf(e.message)
			                                );
			msg.run();
		}
		radiodialog.show_all();
	}

	// Removes entry from the media library
	private void on_remove_button_clicked() {
		Gtk.TreeSelection selection = tv.get_selection ();
		if(selection.count_selected_rows() > 0) {
			TreeIter iter;
			selection.get_selected(null, out iter);
			listmodel.remove(iter);
		}
	}
}

