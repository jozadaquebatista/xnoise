/* xnoise-videoscreen.vala
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

using Xnoise;
using Xnoise.Services;

public class Xnoise.VideoScreen : Gtk.DrawingArea {
	private Gdk.Pixbuf logo_pixb;
	private Gdk.Pixbuf cover_image_pixb;
	private Gdk.Pixbuf logo;
	private unowned Main xn;
	private bool cover_image_available;
	private unowned GstPlayer player;
	private static const string SELECT_EXT_SUBTITLE_FILE = _("Select external subtitle file");
	
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
		int groupcnt = 0;
		if(player.available_subtitles != null) {
			if(rightmenu == null)
				rightmenu = new Menu();
			int i = 0;
			foreach(unowned string s in player.available_subtitles) {
				var menuitem = new ImageMenuItem.from_stock (Gtk.Stock.INDEX, null);
				menuitem.set_label(s);
				int k = i++;
				menuitem.activate.connect( () => { 
					//print("text selected: %d\n", k); 
					this.player.current_text = k;
				});
				rightmenu.append(menuitem);
			}
			if(player.available_subtitles.length > 0)
				groupcnt++;
		}
		if(player.available_audiotracks != null && player.available_audiotracks.length > 1) {
			if(rightmenu == null)
				rightmenu = new Menu();
			if(groupcnt > 0)
				rightmenu.append(new SeparatorMenuItem());
			int i = 0;
			foreach(unowned string s in player.available_audiotracks) {
				var menuitem = new ImageMenuItem.from_stock (Gtk.Stock.INFO, null);
				menuitem.set_label(s);
				int k = i++;
				menuitem.activate.connect( () => { 
					//print("audio selected: %d\n", k); 
					this.player.current_audio = k;
				});
				rightmenu.append(menuitem);
			}
			if(player.available_audiotracks.length > 1)
				groupcnt++;
		}
		if(player.current_has_video_track) {
			if(rightmenu == null)
				rightmenu = new Menu();
			if(groupcnt > 0)
				rightmenu.append(new SeparatorMenuItem());
			var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.EDIT, null);
			menu_item.set_label(SELECT_EXT_SUBTITLE_FILE);
			menu_item.activate.connect(this.open_suburi_filechooser);
			rightmenu.append(menu_item);			
		}
		if(rightmenu != null)
			rightmenu.show_all();
		return rightmenu;
	}
	
	private void open_suburi_filechooser() {
		Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
			SELECT_EXT_SUBTITLE_FILE,
			main_window,
			Gtk.FileChooserAction.OPEN,
			Gtk.Stock.CANCEL,
			Gtk.ResponseType.CANCEL,
			Gtk.Stock.OPEN,
			Gtk.ResponseType.ACCEPT,
			null);
		fcdialog.set_current_folder(Environment.get_home_dir());
		if(fcdialog.run() == Gtk.ResponseType.ACCEPT) {
			File f = File.new_for_path(fcdialog.get_filename());
			//print("got suburi xxx : %s\n", f.get_uri());
			player.set_subtitles_for_current_video(f.get_uri());
		}
		fcdialog.destroy();
		fcdialog = null;
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
		
		if(!gst_player.current_has_video_track) {
		
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
						//Pango
						layout_width  = alloc.width/3; //300; //current_alloc.width - (x_offset + x_margin);
						layout_height = 300; //current_alloc.height - (y_offset + y_margin);
						//---
						
						int cover_image_width  = cover_image_pixb.get_width();
						int cover_image_height = cover_image_pixb.get_height();
						
						if((float)widgetwidth/cover_image_width>(float)widgetheight/cover_image_height)
							ratio = (float)widgetheight/cover_image_height;
						else
							ratio = (float)widgetwidth/cover_image_width;
						
						int ciwidth  = (int)(cover_image_width  * ratio * 0.7);
						int ciheight = (int)(cover_image_height * ratio * 0.7);
						
						//TODO: Set max scale for logo
						var font_description = new Pango.FontDescription();
						font_description.set_family(font_family);
						font_description.set_size((int)(font_size * Pango.SCALE));
		
						var pango_layout = Pango.cairo_create_layout(cr);
						pango_layout.set_font_description(font_description);
						pango_layout.set_markup(get_content_text() , -1);
						
						cr.set_source_rgb(0.0, 0.0, 0.0);    // black background
						cr.paint();
						cr.set_source_rgb(0.9, 0.9, 0.9); // light gray font color
						int pango_x_offset = 50;
						cr.translate(pango_x_offset, (widgetheight/3));
						
						pango_layout.set_width( (int)(layout_width  * Pango.SCALE));
						pango_layout.set_height((int)(layout_height * Pango.SCALE));
						
						pango_layout.set_ellipsize(Pango.EllipsizeMode.END);
						pango_layout.set_alignment(Pango.Alignment.LEFT);
						
						cr.move_to(0, 0);
						Pango.cairo_show_layout(cr, pango_layout);
						cr.move_to(0, 0);
						cr.translate(-pango_x_offset, -(widgetheight/3));
						
						logo = cover_image_pixb.scale_simple(ciwidth, ciheight, Gdk.InterpType.HYPER);
						
						y_offset = (int)((widgetheight * 0.5)  - (ciheight * 0.5));
						x_offset = (int)((widgetwidth  * 0.65) - (ciwidth  * 0.5));
						if(x_offset < (layout_width + pango_x_offset))
							x_offset = layout_width + pango_x_offset;
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
	
	private string get_content_text() {
		string result = "";
		string? uri = global.current_uri;
		
		string? title = global.current_title;
		string? artist = global.current_artist;
		string? album = global.current_album;
	
		string? filename = null;
		if(uri != null) {
			File f = File.new_for_uri(uri);
			if(f != null) {
				filename = f.get_basename();
				filename = Markup.escape_text(filename);
			}
		}
	
		//if neither title nor artist are known, show filename instead
		//if there is no title, the title is the same as the filename
		//shouldn't global rather return null if there is no title?
	
		//todo: handle streams, change label layout, pack into a box with padding and use Tooltip.set_custom
		if((title == null && artist == null && filename != null) || (filename == title /*&& artist == null*/)) {
			result = "<b>" + prepare_name_from_filename(filename) + " </b>";
		}
		else {
			if(album == null)
				album = _("unknown album");
			if(artist == null)
				artist = _("unknown artist");
			if(title == null)
				title = _("unknown title");
			
			album = Markup.escape_text(album);
			artist = Markup.escape_text(artist);
			title = Markup.escape_text(title);
			
			result = "<span weight=\"bold\">" + 
			          title +   " </span>\n<span size=\"small\" rise=\"6000\" style=\"italic\"></span><span size=\"xx-small\">\n</span>" +
			          "<span size=\"small\" weight=\"light\">%s </span>".printf(_("by")) + 
			          artist + " \n" +
			          "<span size=\"small\" weight=\"light\">%s </span> ".printf(_("on")) + 
			          album;
		}
		return result;
	}
	

	public string font_family    { get; set; default = "Sans"; }
	public double font_size      { get; set; default = 18; }
	public string text           { get; set; }
	
	private int layout_width     = 100;
	private int layout_height    = 100;

	public void trigger_expose() {
		this.queue_draw();
	}
}

