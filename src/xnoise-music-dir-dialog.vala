using GLib;
using Gtk;


public class Xnoise.MusicFolderDialog : Gtk.Builder {
	private string[] mfolders;
	private Dialog window;
	private ListStore listmodel;
	private TreeView tv;
	private TreeIter iter; //TODO
	private Button bok;
	private Button bcancel;
	private Button badd;
	private Button brem;
	private string[] list_of_folders; 

	public signal void sign_finish();
	
	public MusicFolderDialog() {
		create_widgets();

		DbWriter dbb = new DbWriter();
		mfolders = dbb.get_music_folders(); 
	
		foreach (weak string mfolder in mfolders) {
			listmodel.append (out iter);
			listmodel.set (iter, 0, mfolder, -1);
		}
		this.window.show_all();	
	}

	~MusicFolderDialog() {
		print("destruct mfd\n");	
	}

	private void deliver_music_folders() {
		list_of_folders = new string[0];
		listmodel.foreach(list_foreach);
	}

	private void create_widgets() {
		try {
			this.add_from_file(Config.UIDIR + "/add_folder.ui");

			window     = this.get_object("musicFolderDialog") as Dialog;
			tv         = this.get_object("tv") as TreeView;
			bok        = this.get_object("OKbutton") as Button;
			bcancel    = this.get_object("Cancelbutton") as Button;
			badd       = this.get_object("Addfolderbutton") as Button;
			brem       = this.get_object("removeButton") as Button;

			bok.clicked+=on_ok_button_clicked_cb;
			bcancel.clicked+=on_cancel_button_clicked_cb;
			badd.clicked+=on_add_folder_button_clicked_cb;
			brem.clicked+=on_remove_button_clicked_cb;

			listmodel = new ListStore(1, typeof(string));
			tv.set_model(listmodel);
			CellRendererText cell = new CellRendererText ();
			cell.set ("foreground_set", true, null);
			tv.insert_column_with_attributes (-1, "Path", cell, "text", 0, null);

			window.set_icon_from_file (Config.UIDIR + "/ente.png");
		} 
		catch (GLib.Error err) {
			var msg = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, 
				Gtk.ButtonsType.CANCEL, "Failed to build dialog! \n" + err.message);
			msg.run();
			return;
		}
		listmodel = new ListStore(1, typeof(string));
		tv.set_model(listmodel);
		CellRendererText cell = new Gtk.CellRendererText ();
		cell.set ("foreground_set", true, null);
		tv.insert_column_with_attributes (-1, "Path", cell, "text", 0, null);
	}

	private bool list_foreach(TreeModel sender, TreePath mypath, TreeIter myiter) { 
		GLib.Value gv;
		sender.get_value(myiter, 0, out gv);
		list_of_folders += gv.get_string();
		return false;
	}

	public void on_ok_button_clicked_cb() {
		Main.instance().main_window.musicBr.set_sensitive(false);
		bok.sensitive = false;
		bcancel.sensitive = false;
		badd.sensitive = false;
		brem.sensitive = false;
		deliver_music_folders();
		try {
			Thread.create(write_music_folder_into_db, false);
		} catch (ThreadError ex) {
			print("Error: %s\n", ex.message);
			return;
		}
		window.destroy();
	}
	
	public void* write_music_folder_into_db() { 
		//thread for the song import to the db
		//sends a signal when finished, this signal is handled by main window
		DbWriter dbb = new DbWriter();
		dbb.write_music_folder_into_db(list_of_folders); //TODO: pass list_of_folders as reference as soon as vala allows this
		mfolders = null;
		print("thread finished\n");
		this.sign_finish();
		return null;
	}

	public void on_cancel_button_clicked_cb() {
		this.window.destroy();
	}

	public void on_add_folder_button_clicked_cb() {
		Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(
			"Select music directory",
			window, 
			Gtk.FileChooserAction.SELECT_FOLDER,
			Gtk.STOCK_CANCEL,
			Gtk.ResponseType.CANCEL,
			Gtk.STOCK_OPEN,
			Gtk.ResponseType.ACCEPT,
			null);
		if (dialog.run() == Gtk.ResponseType.ACCEPT) {
			listmodel.append(out iter);
			listmodel.set(iter, 0, dialog.get_filename (), -1);
		}
		dialog.destroy();
		dialog = null;
	}

	public void on_remove_button_clicked_cb() {
		Gtk.TreeSelection selection = tv.get_selection ();
		if(selection.count_selected_rows() > 0) {
			selection.get_selected (null, out iter);
			GLib.Value gv;
			listmodel.get_value(iter, 0, out gv);
			print("remove folder %s\n",gv.get_string());
			listmodel.remove (iter);
		}
	}
}

