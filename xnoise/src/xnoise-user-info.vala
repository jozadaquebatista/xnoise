/* xnoise-user-info.vala
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

public class Xnoise.UserInfo : GLib.Object {
	
	public enum RemovalType {
		CLOSE_BUTTON = 0, //Info is removed, if close button is clicked
		TIMER,            //Info is removed, if timer has elapsed
		EXTERNAL          //Info is removed, if external function is called with messge id; no remove button available and no timer used
	}

	public enum ContentClass {
		INFO = 0,
		WAIT,
		WARNING,
		QUESTION,
		CRITICAL
	}

	public delegate void AddInfoBarDelegateType(InfoBar ibar);

	private AddInfoBarDelegateType add_info_bar;
	private HashTable<uint, InfoBar> info_messages;
	private uint id_count;

	public UserInfo(AddInfoBarDelegateType func) {
		add_info_bar = func;
		id_count = 1;
		info_messages = new HashTable<uint, InfoBar>(direct_hash, direct_equal);
	}

	private uint get_min(GLib.List<uint> list) {
		uint ret = list.data;
		foreach(uint val in list) {
			if(val < ret)
				ret = val;
		}
		return ret;
	}
	
	private void popdown_oldest() {
		GLib.List<uint> keys = info_messages.get_keys();
		if(keys == null)
			return;
		uint id = get_min(keys);
		if(id == 0)
			return;
		popdown(id);
	}
	
	public void popdown(uint id) {
		InfoBar? bar = info_messages.lookup(id);
		
		if(bar == null)
			return;
		
		info_messages.remove(id);
		
		Idle.add( () => {
			if(bar == null)
				return false;
			bar.hide();
			bar.destroy();
			bar = null;
			return false;
		});
	}

	/*
	 * RemovalType:              how should the infobar be removed
	 * ContentClass:             what is the classification of the content
	 * info_text:                Text to display
	 * appearance_time_seconds:  time used for the case a timer is used popdown
	 * extra_widget:             for example a button to reply a question
	 * returns:                  messge id for removal of info bars
	 */
	public uint popup(RemovalType removal_type,
	               ContentClass content_class,
	               string info_text = "",
	               int appearance_time_seconds = 2, 
	               Widget? extra_widget = null) {
		
		uint current_id = id_count;
		id_count++;
		
		var bar           = new InfoBar();
		var symbol_widget = create_symbol_widget(content_class);
		var info_label    = new Label(info_text);
		var content_area  = bar.get_content_area();
		var bx            = new Gtk.HBox(false, 0);
		
		if(symbol_widget != null)
			bx.pack_start(symbol_widget, false, false , 0);
		
		info_label.set_ellipsize(Pango.EllipsizeMode.END);
		bx.pack_start(info_label, true, true , 0);

		if(extra_widget != null)
			bx.pack_start(symbol_widget, false, false , 0);

		switch(removal_type) {
			case(RemovalType.CLOSE_BUTTON):
				var close_button = new Button.from_stock(Gtk.STOCK_CLOSE);
				close_button.clicked.connect( () => {
					this.popdown(current_id);
				});
				bx.pack_start(close_button, false, false , 0);
				break;
			case(RemovalType.TIMER):
				Timeout.add_seconds(appearance_time_seconds, 
					                () => {
					if(MainContext.current_source().is_destroyed())
						return false;
					this.popdown(current_id);
					return false;
				});
				break;
			default:
				break;
		}
		((Container)content_area).add(bx);

		info_messages.insert(current_id, bar);
		this.add_info_bar(bar); //Main.instance.main_window.show_status_info(bar);
		bar.show_all();
		
		if(info_messages.size() > 3)
			this.popdown_oldest();
		
		return current_id;
	}

	private Widget? create_symbol_widget(ContentClass content_class) {
		Widget? ret = null;
		switch(content_class) {
			case(ContentClass.INFO):
				var info_image = new Gtk.Image.from_stock(Gtk.STOCK_DIALOG_INFO, Gtk.IconSize.MENU);
				ret = info_image;
				break;
			case(ContentClass.WAIT):
				var spinner = new Gtk.Spinner();
				spinner.start();
				ret = spinner;
				break;
			case(ContentClass.WARNING):
				var info_image = new Gtk.Image.from_stock(Gtk.STOCK_DIALOG_WARNING, Gtk.IconSize.MENU);
				ret = info_image;
				break;
			case(ContentClass.QUESTION):
				var info_image = new Gtk.Image.from_stock(Gtk.STOCK_DIALOG_QUESTION, Gtk.IconSize.MENU);
				ret = info_image;
				break;
			case(ContentClass.CRITICAL):
				var info_image = new Gtk.Image.from_stock(Gtk.STOCK_DIALOG_ERROR, Gtk.IconSize.LARGE_TOOLBAR);
				ret = info_image;
				break;
			default:
				break;
		}
		return ret;
	}

}

