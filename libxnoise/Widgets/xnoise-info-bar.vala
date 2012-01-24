/* xnoise-info-bar.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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



public class Xnoise.InfoBar : Gtk.InfoBar {

	private Gtk.Label info_label;
	private Gtk.Widget symbol_widget;
	private UserInfo uinf; 
	private UserInfo.RemovalType removal_type;
	private Gtk.Button? close_button = null;
	private Gtk.Widget? extra_widget = null;
	private uint current_id = 0;
	
	public InfoBar(UserInfo _uinf, 
	               UserInfo.ContentClass _content_class, 
	               UserInfo.RemovalType _removal_type,
	               uint _current_id,
	               int _appearance_time_seconds = 5,
	               string _info_text = "", 
	               bool bold = true,
	               Gtk.Widget? _extra_widget = null) {
		
		uinf          = _uinf; 
		removal_type  = _removal_type;
		current_id = _current_id;
		extra_widget  = _extra_widget;
		setup_layout(_content_class, _info_text, bold, _appearance_time_seconds);
	}

	//~InfoBar() {
	//	print("destruct info bar\n");
	//}
	
	public void enable_close_button(bool enable) {
		if(close_button == null)
			return;
		
		close_button.sensitive = enable;
	}
	
	public void update_symbol_widget(UserInfo.ContentClass cc) {
		symbol_widget.hide();
		symbol_widget.destroy();
		symbol_widget = create_symbol_widget(cc);
		swbox.pack_start(symbol_widget, false, false , 2);
		symbol_widget.show_all();
	}
	
	public void update_text(string txt, bool bold = true) {
		info_label.use_markup = true;
		if(bold)
			info_label.set_markup(Markup.printf_escaped("<b>%s</b>", txt));
		else
			info_label.set_markup(Markup.printf_escaped("%s", txt));
	}
	
	public void update_extra_widget(Gtk.Widget? widget) {
		if(widget != null) {
			extra_widget.hide();
			extra_widget.destroy();
			extra_widget = widget;
			ewbox.pack_start(extra_widget, false, false , 0);
			extra_widget.show_all();
		}
		else {
			if(extra_widget != null) {
				extra_widget.hide();
				extra_widget.destroy();
			}
		}
	}
	
	public unowned Gtk.Widget? get_extra_widget() {
		return extra_widget;
	}
	
	private Gtk.Box swbox;
	private Gtk.Box ewbox;
	
	private void setup_layout(UserInfo.ContentClass content_class, string info_text, bool bold = true, int appearance_time_seconds) {
		symbol_widget     = create_symbol_widget(content_class);
		info_label        = new Gtk.Label(null);
		var content_area  = this.get_content_area();
		var bx            = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		swbox             = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		ewbox             = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		
		update_text(info_text, bold);
		
		bx.pack_start(swbox, false, false , 4);
		
		if(symbol_widget != null)
			swbox.pack_start(symbol_widget, false, false , 0);
		
		info_label.set_ellipsize(Pango.EllipsizeMode.END);
		info_label.set_hexpand(true);
		bx.pack_start(info_label, true, true , 2);
		
		bx.pack_start(ewbox, false, false , 0);
		
		if(extra_widget != null)
			ewbox.pack_start(extra_widget, false, false , 0);
		
		switch(removal_type) {
			case(UserInfo.RemovalType.CLOSE_BUTTON):
				close_button = new Gtk.Button.from_stock(Gtk.Stock.CLOSE);
				close_button.clicked.connect( () => {
					Idle.add( () => {
						uinf.popdown(current_id);
						return false;
					});
				});
				bx.pack_start(close_button, false, false , 0);
				break;
			case(UserInfo.RemovalType.TIMER):
				Timeout.add_seconds(appearance_time_seconds, 
				                    () => {
										if(MainContext.current_source().is_destroyed())
											return false;
										uinf.popdown(current_id);
										return false;
				});
				break;
			case(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON):
				Timeout.add_seconds(appearance_time_seconds, 
				                    () => {
										if(MainContext.current_source().is_destroyed())
											return false;
										uinf.popdown(current_id);
										return false;
				});
				close_button = new Gtk.Button.from_stock(Gtk.Stock.CLOSE);
				close_button.clicked.connect( () => {
					Idle.add( () => {
						if(MainContext.current_source().is_destroyed())
							return false;
						uinf.popdown(current_id);
						return false;
					});
				});
				bx.pack_start(close_button, false, false , 0);
				break;
			default:
				break;
		}
		((Gtk.Container)content_area).add(bx);
	}

	private Gtk.Widget? create_symbol_widget(UserInfo.ContentClass content_class) {
		Gtk.Widget? ret = null;
		switch(content_class) {
			case(UserInfo.ContentClass.INFO):
				var info_image = new Gtk.Image.from_stock(Gtk.Stock.DIALOG_INFO, Gtk.IconSize.MENU);
				ret = info_image;
				break;
			case(UserInfo.ContentClass.WAIT):
				var spinner = new Gtk.Spinner();
				spinner.start();
				ret = spinner;
				break;
			case(UserInfo.ContentClass.WARNING):
				var info_image = new Gtk.Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.MENU);
				ret = info_image;
				break;
			case(UserInfo.ContentClass.QUESTION):
				var info_image = new Gtk.Image.from_stock(Gtk.Stock.DIALOG_QUESTION, Gtk.IconSize.MENU);
				ret = info_image;
				break;
			case(UserInfo.ContentClass.CRITICAL):
				var info_image = new Gtk.Image.from_stock(Gtk.Stock.DIALOG_ERROR, Gtk.IconSize.LARGE_TOOLBAR);
				ret = info_image;
				break;
			default:
				break;
		}
		return ret;
	}
}

