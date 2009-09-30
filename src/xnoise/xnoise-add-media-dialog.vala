/* xnoise-mediafolder-dialog.vala
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

public class Xnoise.MediaFolderDialog : GLib.Object {
	
	private const string XNOISEICON = Config.UIDIR + "xnoise_16x16.png";
	private Gtk.Dialog dialog;
	public Gtk.Builder builder;
	private ListStore listmodel;
	private TreeView tv;
	private string[] list_of_folders;
	private string[] list_of_streams; 
	
	public signal void sign_finish();
	
	public MediaFolderDialog() {
		builder = new Gtk.Builder();
		create_widgets();
		
		fill_media_list();

		this.dialog.show_all();	
	}

//	~MediaFolderDialog() {
//		print("destruct mfd\n");	
//	}
	
	private void fill_media_list() {
		return_if_fail(listmodel!=null);
		
		DbBrowser dbb = new DbBrowser();
		
		//add folders
		var mfolders = dbb.get_music_folders(); 
		foreach(string mfolder in mfolders) {
			TreeIter iter;
			listmodel.append (out iter);
			listmodel.set(iter, 
			              0, mfolder, 
			              1, MediaStorageType.FOLDER,
			              -1
			              );
		}
		
		//add streams
		var streams = dbb.get_radio_stations();
		foreach(StreamData sd in streams) {
			TreeIter iter;
			listmodel.append (out iter);
			listmodel.set(iter, 
			              0, sd.Uri, 
			              1, MediaStorageType.STREAM,
			              -1
			              );
		}		
	}

	private void harvest_media_locations() {
		list_of_streams = {};
		list_of_folders = {};
		listmodel.foreach(list_foreach);
	}

	private void create_widgets() {
		try {
			dialog = new Dialog();
			dialog.set_modal(true);
			builder.add_from_file(Config.UIDIR + "add_media.ui");
			
			var mainvbox     = builder.get_object("mainvbox") as Gtk.VBox;
			
			tv               = builder.get_object("tv") as TreeView;
			var baddfile         = builder.get_object("addfilebutton") as Button;
			var baddfolder       = builder.get_object("addfolderbutton") as Button;
			var baddradio        = builder.get_object("addradiobutton") as Button;
			var brem             = builder.get_object("removeButton") as Button;
			
			var bcancel          = (Button)this.dialog.add_button(Gtk.STOCK_CANCEL , 0);
			var bok              = (Button)this.dialog.add_button(Gtk.STOCK_OK, 1);
			
			bok.clicked        += on_ok_button_clicked;
			bcancel.clicked    += on_cancel_button_clicked;
			baddfile.clicked   += on_add_file_button_clicked;
			baddfolder.clicked += on_add_folder_button_clicked;
			baddradio.clicked  += on_add_radio_button_clicked;
			brem.clicked       += on_remove_button_clicked;

			this.dialog.vbox.add(mainvbox);
			this.dialog.set_icon_from_file(XNOISEICON);
			this.dialog.set_title(_("xnoise - Add media to library"));
		} 
		catch (GLib.Error err) {
			var msg = new Gtk.MessageDialog(null, 
			                                Gtk.DialogFlags.MODAL, 
			                                Gtk.MessageType.ERROR, 
			                                Gtk.ButtonsType.CANCEL, 
			                                "Failed to build dialog! \n" + err.message);
			msg.run();
			return;
		}
		
		listmodel = new ListStore(2, typeof(string), typeof(int));
		tv.set_model(listmodel);
		CellRendererText cell = new Gtk.CellRendererText ();
		cell.set("foreground_set", true, null);
		tv.insert_column_with_attributes(-1, "Path", cell, "text", 0, null);
	}

	private bool list_foreach(TreeModel sender, TreePath mypath, TreeIter myiter) { 
		string gv;
		MediaStorageType mst;
		sender.get(myiter, 
		           0, out gv,
		           1, out mst,
		           -1
		           );
		if(mst==MediaStorageType.FOLDER) {
			print("is folder\n");
			list_of_folders += gv;
		}
		if(mst==MediaStorageType.STREAM) {
			print("found stream: gv\n");
			list_of_streams += gv;
		}
		return false;
	}

	private void on_ok_button_clicked() {
		Main.instance().main_window.searchEntryMB.set_sensitive(false);
		Main.instance().main_window.mediaBr.set_sensitive(false);
		harvest_media_locations();
		try {
			Thread.create(write_media_to_db, false);
		} catch (ThreadError ex) {
			print("Error: %s\n", ex.message);
			return;
		}
		this.dialog.destroy();
	}
	
	private void* write_media_to_db() { 
		// thread function for the import to the library
		// sends a signal when finished, this signal is handled by main window
		DbWriter dbb = new DbWriter();
		dbb.write_music_folder_into_db(list_of_folders); //TODO: pass list_of_folders as reference as soon as vala allows this
		foreach(string uri in list_of_streams) {
			print(" xxx: %s\n", uri);
			dbb.add_radio_staion(uri);
		}
		// print("thread finished\n");
		this.sign_finish();
		return null;
	}

	private void on_cancel_button_clicked() {
		this.dialog.destroy();
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
		if (fcdialog.run() == Gtk.ResponseType.ACCEPT) {
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
		radioentry.icon_press += (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
			if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = "";
		};
		radiodialog.vbox.pack_start(radioentry, true, true, 0);
					
		var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.STOCK_CANCEL, 0);
		radiocancelbutton.clicked += () => {
			radiodialog.close();
			radiodialog = null;
		};
		
		var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.STOCK_OK, 1);
		radiookbutton.clicked += () => {
			File file = File.new_for_commandline_arg(radioentry.text);
			if(file.query_exists(null)) {
				TreeIter iter;
				listmodel.append(out iter);
				listmodel.set(iter, 
			              0, radioentry.text, 
			              1, MediaStorageType.STREAM,
			              -1);
			};
			radiodialog.close();
			radiodialog = null;
		};

		radiodialog.destroy_event += () => {
			radiodialog = null;
		};
		
		try {
			radiodialog.set_icon_from_file(XNOISEICON);
			radiodialog.set_title(_("Add internet radio link"));
		}
		catch(GLib.Error err) {
			var msg = new Gtk.MessageDialog(null, 
			                                Gtk.DialogFlags.MODAL, 
			                                Gtk.MessageType.ERROR, 
			                                Gtk.ButtonsType.CANCEL, 
			                                "Failed set icon! \n" + err.message
			                                );
			msg.run();
		}
		radiodialog.show_all();
	}

	
	/**
	* Removes entry from the media library
	*/
	private void on_remove_button_clicked() {
		Gtk.TreeSelection selection = tv.get_selection ();
		if(selection.count_selected_rows() > 0) {
			TreeIter iter;
			selection.get_selected (null, out iter);
			GLib.Value gv;
			listmodel.get_value(iter, 0, out gv);
			listmodel.remove (iter);
		}
	}
}

