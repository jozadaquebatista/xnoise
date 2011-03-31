/* xnoise-videoscreen.vala
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

public class Xnoise.VideoScreen : Gtk.DrawingArea {
	private Gdk.Pixbuf logo_pixb;
	private Gdk.Pixbuf cover_image_pixb;
	private Gdk.Pixbuf logo;
	private unowned Main xn;
	private bool cover_image_available;
	private unowned GstPlayer player;
	
	public VideoScreen(GstPlayer _player) {
		this.player = _player;
		this.xn = Main.instance;
		rect = Gdk.Rectangle();
		Gdk.Color.parse("black", out black);
		init_video_screen();
		cover_image_available = false;
		global.notify["image-path-large"].connect(on_image_path_changed);
		this.button_release_event.connect(on_button_released);
	}

	private bool on_button_released(Gdk.EventButton e) {
		if(!((e.button==3) && (e.type==Gdk.EventType.BUTTON_RELEASE))) {
			return false; //exit here, if it's no the button 3 single click release
		}
		else {
			Menu? menu = create_rightclick_menu();
			if(menu != null)
				menu.popup(null, null, null, 0, e.time);
		}
		return true;
	}

	private Menu? create_rightclick_menu() {
		Menu rightmenu = null;
		if(player.available_subtitles != null) {
			rightmenu = new Menu();
			int i = 0;
			var menuitem_empty = new MenuItem();
			var menuitemHbox_empty = new HBox(false, 1);
			var menuitemLabel_empty = new Label(_("No Subtitle"));
			var menuitemimage_empty = new Gtk.Image();
			menuitemimage_empty.set_from_stock(Gtk.Stock.INFO, IconSize.MENU);
			menuitemHbox_empty.set_homogeneous(false);
			menuitemHbox_empty.pack_start(menuitemimage_empty, false, false, 0);
			menuitemHbox_empty.pack_start(menuitemLabel_empty, true, true, 0);
			menuitem_empty.add(menuitemHbox_empty);
			menuitem_empty.activate.connect( () => { 
				print("menuitem selected: %d\n", 0); 
				this.player.current_text = -1;
			});
			rightmenu.append(menuitem_empty);

			foreach(unowned string s in player.available_subtitles) {
				var menuitem = new MenuItem();
				var menuitemHbox = new HBox(false, 1);
				var menuitemLabel = new Label(s);
				var menuitemimage = new Gtk.Image();
				menuitemimage.set_from_stock(Gtk.Stock.INFO, IconSize.MENU);
				menuitemHbox.set_homogeneous(false);
				menuitemHbox.pack_start(menuitemimage, false, false, 0);
				menuitemHbox.pack_start(menuitemLabel, true, true, 0);
				menuitem.add(menuitemHbox);
				int k = ++i;
				menuitem.activate.connect( () => { 
					print("menuitem selected: %d\n", k); 
					this.player.current_text = k;
				});
				rightmenu.append(menuitem);
			}
			rightmenu.show_all();
		}
		return rightmenu;
	}

	private void on_image_path_changed() {
		//print("on_image_path_changed %s\n", global.image_path_large);
		if(global.image_path_large != null) {
			try {
				cover_image_pixb = new Gdk.Pixbuf.from_file(global.image_path_large);
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
				return;
			}
			cover_image_available = true;
			if(this.visible) {
				Gdk.Window w = this.get_window();
				if(w != null) 
					w.invalidate_rect(null, false);
			}
				
		}
		else {
			cover_image_pixb = null;
			cover_image_available = false;
		}
	}
	
	private void init_video_screen() {
		this.set_double_buffered(false);
		this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK |Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK);
		try {
			logo_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "xnoise_bruit.svg");
		}
		catch(GLib.Error e) {
			print("%s\n", e.message);
		}
	}
	
	private Gdk.Region region;
	
	private Gdk.Rectangle rect;
	
	private Gdk.Color black;
	
	public override bool expose_event(Gdk.EventExpose e) {
		
		if(e.count > 0) return true; //exposure compression
		
		rect.x = 0;
		rect.y = 0;
		Gtk.Allocation alloc;
		this.get_allocation(out alloc);
		rect.width  = e.area.width;
		rect.height = e.area.height;
		region = Gdk.Region.rectangle(rect);
		
		this.get_window().begin_paint_region(region);
		Cairo.Context cr = Gdk.cairo_create(e.window);
		
		Gdk.cairo_set_source_color(cr, black);
		cr.rectangle(e.area.x, e.area.y,
		             e.area.width, e.area.height);
		cr.fill();
		
		if(!xn.gPl.current_has_video) {
		
			int y_offset;
			int x_offset;
		
			//print("current has no video\n");
			if(this.logo_pixb!=null) {
				logo = null;
				int logowidth, logoheight, widgetwidth, widgetheight;
				float ratio;
				
				logowidth  = logo_pixb.get_width();
				logoheight = logo_pixb.get_height();
				widgetwidth  = alloc.width;
				widgetheight = alloc.height;

				if((float)widgetwidth/logowidth>(float)widgetheight/logoheight)
					ratio = (float)widgetheight/logoheight;
				else
					ratio = (float)widgetwidth/logowidth;

				logowidth  = (int)(logowidth  *ratio);
				logoheight = (int)(logoheight *ratio);

				if(logowidth<=1||logoheight<=1) {
					// Do not paint for small pictures
					this.get_window().end_paint();
					return true;
				}
				if(!cover_image_available) {
					logo = logo_pixb.scale_simple((int)(logowidth * 0.8), (int)(logoheight * 0.8), Gdk.InterpType.HYPER);
					y_offset = (int)((widgetheight * 0.5) - (logoheight * 0.4));
					x_offset = (int)((widgetwidth  * 0.5) - (logowidth  * 0.4));
				}
				else {
					if(cover_image_pixb != null) {
						int cover_image_width  = cover_image_pixb.get_width();
						int cover_image_height = cover_image_pixb.get_height();

						if((float)widgetwidth/cover_image_width>(float)widgetheight/cover_image_height)
							ratio = (float)widgetheight/cover_image_height;
						else
							ratio = (float)widgetwidth/cover_image_width;

						int ciwidth  = (int)(cover_image_width  * ratio * 0.8);
						int ciheight = (int)(cover_image_height * ratio * 0.8);
						
						//TODO: Set max scale
						
						logo = cover_image_pixb.scale_simple(ciwidth, ciheight, Gdk.InterpType.HYPER);

						y_offset = (int)((widgetheight * 0.5) - (ciheight * 0.5));
						x_offset = (int)((widgetwidth  * 0.5) - (ciwidth  * 0.5));
					}
					else {
						logo = logo_pixb.scale_simple((int)(logowidth * 0.8), (int)(logoheight * 0.8), Gdk.InterpType.HYPER);
						y_offset = (int)((widgetheight * 0.5) - (logoheight * 0.4));
						x_offset = (int)((widgetwidth  * 0.5) - (logowidth  * 0.4));
					}
				}
				Gdk.cairo_set_source_pixbuf(cr, logo, x_offset, y_offset);
				cr.paint();
			}
			this.get_window().end_paint();
		}
		return true;
	}

	public void trigger_expose() {
		//trigger a redraw by gtk using our expose_event handler
		Gtk.Allocation alloc;
		this.get_allocation(out alloc);
		this.queue_draw_area(0, 0, alloc.width, alloc.height);
	}
}

