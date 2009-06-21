/* xnoise-plugin-gui-element.vala
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

public class Xnoise.PluginGuiElement : Gtk.HBox {
	Gtk.CheckButton cb;
	Gtk.Image image;
	Gtk.Label label;

	public PluginGuiElement(string name, 
	                        string description, 
							string icon, 
							string author, 
							string website, 
							string license, 
							string copyright) {
	//	this.set_label("dfghdgf");
	//	print("cnstruct PluginGuiElement\n");
		cb = new Gtk.CheckButton();
		cb.active = false;
		image = new Gtk.Image.from_stock(Gtk.STOCK_FIND, Gtk.IconSize.LARGE_TOOLBAR);
		label = new Gtk.Label("<b>" + name + "</b>" + "\n" + description);
		label.use_markup = true;
		this.pack_start(cb, false, false, 0);
		this.pack_start(image, false, false, 0);
		this.pack_start(label, false, true, 0);
		this.show_all();
	}
}
