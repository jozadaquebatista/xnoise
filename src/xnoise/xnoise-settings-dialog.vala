/* xnoise-settings-dialog.vala
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

using GLib;
using Gtk;

public class Xnoise.SettingsDialog : Gtk.Builder, IParams {
	private const string SETTINGS_UI_FILE = Config.DATADIR + "ui/settings.ui";
	public Gtk.Dialog dialog;
	private Gtk.SpinButton sb;
	private int fontsizeMB;

	public signal void sign_finish();

	public SettingsDialog() {
		if(setup_widgets()) {
			this.get_current_settings();
			this.dialog.show_all();	
		}
	}
	
	private void on_mb_font_changed(Gtk.SpinButton sender) {
		if((int)(sender.value) < 7 ) sender.value = 7;
		if((int)(sender.value) > 15) sender.value = 15;
		fontsizeMB = (int)sender.value;
		Main.instance().main_window.musicBr.fontsizeMB = fontsizeMB;
		//TODO:immediatly do something with the new value
	}
	
	private void on_ok_button_clicked() {
//		Params.instance().write_to_file_for_single(this);
		this.dialog.destroy();
	}

	private void on_cancel_button_clicked() {
		this.dialog.destroy();
	}
	
	private void get_current_settings() {
//		Params.instance().read_from_file_for_single(this);
	}
		
	public void read_params_data() {
//		this.fontsizeMB = file.get_integer("settings", "fontsizeMB");
//		this.sb.value = this.fontsizeMB;
	}

	public void write_params_data() {
//		file.set_integer("settings", "fontsizeMB", fontsizeMB);
	}

	private MusicFolderDialog mfd;
	private void on_music_add_clicked(Gtk.Button sender) {
		mfd = new MusicFolderDialog();
		mfd.sign_finish += () => {
			mfd = null;
			Idle.add(Main.instance().main_window.musicBr.change_model_data);	
		};
	}
	
	private bool setup_widgets() {
		try {
			assert(GLib.FileUtils.test(SETTINGS_UI_FILE, FileTest.EXISTS));
			
			this.add_from_file(SETTINGS_UI_FILE);
			this.dialog = this.get_object("dialog1") as Gtk.Dialog;

			var okButton             = this.get_object("button2") as Gtk.Button;
			okButton.can_focus       = false;
			okButton.clicked         += this.on_ok_button_clicked;
			
			var cancelButton         = this.get_object("button1") as Gtk.Button;
			cancelButton.can_focus   = false;
			cancelButton.clicked     += this.on_cancel_button_clicked;
			
			sb                       = this.get_object("spinbutton1") as Gtk.SpinButton;
			sb.changed               += this.on_mb_font_changed;
			
			var musicAddButton       = this.get_object("button3") as Gtk.Button;
			musicAddButton.can_focus = false;
			musicAddButton.clicked   += this.on_music_add_clicked;
			
			this.dialog.set_icon_from_file (Config.UIDIR + "xnoise_16x16.png");
		} 
		catch (GLib.Error err) {
			var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, 
				Gtk.ButtonsType.OK, "Failed to build settings window! \n" + err.message);
			msg.run();
			return false;
		}
		return true;
	}
}
