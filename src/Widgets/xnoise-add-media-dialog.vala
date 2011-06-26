/* xnoise-add-media-dialog.vala
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

public class Xnoise.AddMediaDialog : GLib.Object {

	private const string XNOISEICON = Config.UIDIR + "xnoise_16x16.png";
	private Gtk.Dialog dialog;
	private ListStore listmodel;
	private TreeView tv;
	private CheckButton fullrescancheckb;
	private string[] list_of_folders;
	private string[] list_of_files;
	private string[] list_of_streams;
	private unowned Main xn;
	
	public Gtk.Builder builder;

	private enum MediaStorageType {
		FILE = 0,
		FOLDER,
		STREAM
	}

	public signal void sign_finish();

	public AddMediaDialog() {
		xn = Main.instance;
		builder = new Gtk.Builder();
		create_widgets();
		
		fill_media_list();
		
		dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
		dialog.show_all();
	}

	//	~AddMediaDialog() {
	//		print("destruct amd\n");
	//	}

	private void fill_media_list() {
		return_if_fail(listmodel != null);
		
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE, put_media_data_to_model);
		db_worker.push_job(job);
	}
	
	private StreamData[] streams = null;
	
	private bool put_media_data_to_model(Worker.Job job) {
		//add folders
		string[] mfolders = db_browser.get_media_folders();
		job.set_arg("mfolders", mfolders);
		
		//add files
		string[] mfiles = db_browser.get_media_files();
		job.set_arg("mfiles", mfiles);
		
		//add streams to list
		streams = db_browser.get_streams();
		
		Idle.add( () => {
			foreach(string mfolder in ((string[])job.get_arg("mfolders"))) {
				TreeIter iter;
				listmodel.append(out iter);
				listmodel.set(iter,
					          0, mfolder,
					          1, MediaStorageType.FOLDER,
					          -1
					          );
			}
			return false;
		});
		
		Idle.add( () => {
			//print("mfiles length: %d\n", mfiles.length);
			foreach(string uri in ((string[])job.get_arg("mfiles"))) {
				File file = File.new_for_uri(uri);
				TreeIter iter;
				listmodel.append(out iter);
				listmodel.set(iter,
					          0, file.get_path(),
					          1, MediaStorageType.FILE,
					          -1
					          );
			}
			return false;
		});
		
		Idle.add( () => {
			foreach(StreamData sd in streams) {
				TreeIter iter;
				listmodel.append(out iter);
				listmodel.set(iter,
					          0, sd.uri,
					          1, MediaStorageType.STREAM,
					          -1
					          );
			}
			streams = null;
			return false;
		});
		return false;
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
			dialog.set_transient_for(main_window);
			
			builder.add_from_file(Config.UIDIR + "add_media.ui");
			
			var mainvbox           = builder.get_object("mainvbox") as Gtk.VBox;
			tv                     = builder.get_object("tv") as TreeView;
			var baddfolder         = builder.get_object("addfolderbutton") as Button;
			var baddradio          = builder.get_object("addradiobutton") as Button;
			var brem               = builder.get_object("removeButton") as Button;
			
			var labeladdfolder     = builder.get_object("labeladdfolder") as Label;
			var labeladdstream     = builder.get_object("labeladdstream") as Label;
			var labelremove        = builder.get_object("labelremove") as Label;
			var descriptionlabel   = builder.get_object("descriptionlabel") as Label;
			
			fullrescancheckb       = builder.get_object("fullrescancheckb") as CheckButton;
			var bcancel            = (Button)this.dialog.add_button(Gtk.Stock.CANCEL, 0);
			var bok                = (Button)this.dialog.add_button(Gtk.Stock.OK, 1);
			
			labeladdfolder.label   = _("Add local folder");
			labeladdstream.label   = _("Add media stream");
			labelremove.label      = _("Remove");
			fullrescancheckb.label = _("do a full rescan of the library");
			descriptionlabel.label = _("Select local media folders or remote media streams. \nAll library media will be available in the library.");
			
			bok.clicked.connect(on_ok_button_clicked);
			bcancel.clicked.connect(on_cancel_button_clicked);
			baddfolder.clicked.connect(on_add_folder_button_clicked);
			baddradio.clicked.connect(on_add_radio_button_clicked);
			brem.clicked.connect(on_remove_button_clicked);
			
			((Gtk.VBox)this.dialog.get_content_area()).add(mainvbox);
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

	private void on_ok_button_clicked() {
		bool interrupted_populate_model = false;
		if(main_window.mediaBr.mediabrowsermodel.populating_model) {
			interrupted_populate_model = true; // that means we have to complete filling of the model after import
			//print("was still populating model\n");
		}
		
		main_window.mediaBr.mediabrowsermodel.cancel_fill_model();
		var prg_bar = new Gtk.ProgressBar();
		prg_bar.set_fraction(0.0);
		prg_bar.set_text("0 / 0");
		
		Timeout.add(200, () => {
			uint msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
			                    UserInfo.ContentClass.WAIT,
			                    _("Importing media data. This may take some time..."),
			                    true,
			                    5,
			                    prg_bar);
			
			harvest_media_locations();
			
			global.media_import_in_progress = true;
			
			if(fullrescancheckb.get_active())
				main_window.mediaBr.mediabrowsermodel.remove_all(); // when doing a full import db_ids may change
			
			media_importer.import_media_groups(list_of_streams, list_of_files, list_of_folders, msg_id, fullrescancheckb.get_active(), interrupted_populate_model);
			
			this.dialog.destroy();
			this.sign_finish();
			return false;
		});
	}

	private void on_cancel_button_clicked() {
		this.dialog.destroy();
		this.sign_finish();
	}

	private void on_add_folder_button_clicked() {
		Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
			_("Select media folder"),
			this.dialog,
			Gtk.FileChooserAction.SELECT_FOLDER,
			Gtk.Stock.CANCEL,
			Gtk.ResponseType.CANCEL,
			Gtk.Stock.OPEN,
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
		radioentry.secondary_icon_stock = Gtk.Stock.CLEAR;
		radioentry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
		radioentry.icon_press.connect( (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
			if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = "";
		});
		((Gtk.VBox)radiodialog.get_content_area()).pack_start(radioentry, true, true, 0);

		var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.CANCEL, 0);
		radiocancelbutton.clicked.connect( () => {
			radiodialog.close();
			radiodialog = null;
		});

		var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.OK, 1);
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

