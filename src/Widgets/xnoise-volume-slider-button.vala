/* xnoise-volume-slider-button.vala
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
 * 	softshaker
 */


using Gtk;

/**
* A VolumeSliderButton is a Gtk.VolumeButton used to change the volume
*/
public class Xnoise.VolumeSliderButton : Gtk.VolumeButton {
	private Main xn;
	public VolumeSliderButton() {
		this.xn = Main.instance;
		this.size = Gtk.IconSize.LARGE_TOOLBAR;
		this.can_focus = false;
		this.relief = Gtk.ReliefStyle.NONE;
		this.set_value(0.3); //Default value
		this.value_changed.connect(on_change);
		gPl.sign_volume_changed.connect(on_volume_change);
	}

	private void on_change() {
		gPl.volume = get_value();
	}

	private void on_volume_change(double val) {
		this.set_sensitive(false);
		this.value_changed.disconnect(on_change);
		this.set_value(val);
		this.value_changed.connect(on_change);
		this.set_sensitive(true);
	}
}

