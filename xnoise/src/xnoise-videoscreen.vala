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

public class Xnoise.VideoScreen : Gtk.DrawingArea {
	private Gdk.Pixbuf logo_pixb;
	private Gdk.Pixbuf cover_image_pixb;
	private Main xn;
	private bool cover_image_available;

	public VideoScreen() {
		this.xn = Main.instance;
		init_video_screen();
		cover_image_available = false;
		global.notify["image-path-large"].connect(on_image_path_changed);
	}

	private void on_image_path_changed() {
		if(global.image_path_large != null) {
			try {
				cover_image_pixb = new Gdk.Pixbuf.from_file(global.image_path_large);
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
				return;
			}
			cover_image_available = true;
		}
		else {
			cover_image_pixb = null;
			cover_image_available = false;
		}
	}
	
	private void init_video_screen() {
		this.set_double_buffered(false);
		this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK);
		try {
			logo_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "xnoise_bruit.svg");
			//TODO: Make a new logo. This is not too nice
		}
		catch(GLib.Error e) {
			print("%s\n", e.message);
		}
	}

	public override bool expose_event(Gdk.EventExpose e) {

		if(e.count > 0) return true; //exposure compression

		Gdk.draw_rectangle(this.window,
		                   this.style.black_gc, true,
		                   e.area.x, e.area.y,
		                   e.area.width, e.area.height
		                   );

		if(!xn.gPl.current_has_video) {
			
			if(!cover_image_available) {
				draw_pixbuf(logo_pixb, e);
			}
			else {
				if(cover_image_pixb != null)
					draw_pixbuf(cover_image_pixb, e);
				else
					draw_pixbuf(logo_pixb, e);
			}
		}
			
		else if(this.window!=null) {
			Gdk.draw_rectangle(this.window,
			                   this.style.black_gc, true,
			                   e.area.x, e.area.y,
			                   e.area.width, e.area.height
			                   );
		}
		return true;
	}
	
	
	public void draw_pixbuf(Gdk.Pixbuf pixb, Gdk.EventExpose e) {
		if (pixb == null) return;
		Gdk.Pixbuf drawing_pb = null;
		
		int pixbwidth, pixbheight, widgetwidth, widgetheight;
		float ratio;
		var region = new Gdk.Region();
		var rect = Gdk.Rectangle();
		rect.x = 0;
		rect.y = 0;
		rect.width  = this.allocation.width;
		rect.height = this.allocation.height;
		region = Gdk.Region.rectangle(rect);

		this.window.begin_paint_region(region);
		Gdk.draw_rectangle(this.window,
		                   this.style.black_gc, true,
		                   e.area.x, e.area.y,
		                   e.area.width, e.area.height
		                   );
		                   
		pixbwidth  = pixb.get_width();
		pixbheight = pixb.get_height();
		widgetwidth  = this.allocation.width;
		widgetheight = this.allocation.height;
		
		if(widgetwidth == 0 || widgetheight == 0 || pixbwidth == 0 || pixbheight == 0) {
			this.window.end_paint();
			return;
		}

		if((float)widgetwidth/pixbwidth>(float)widgetheight/pixbheight)
			ratio = (float)widgetheight/pixbheight;
		else
			ratio = (float)widgetwidth/pixbwidth;
		
		pixbwidth = (int)(pixbwidth*ratio);
		pixbheight = (int)(pixbheight*ratio);
		
		if(pixbwidth<=1||pixbheight<=1) {
			// Do not paint for small pictures
			this.window.end_paint();
			return;
		}
		
		drawing_pb = pixb.scale_simple((int)(pixbwidth * 0.8), (int)(pixbheight * 0.8), Gdk.InterpType.HYPER);
		if (drawing_pb == null) {
			this.window.end_paint(); 
			return;
		}
		
		int y_offset = (int)((widgetheight * 0.5) - (pixbheight * 0.4));
		int x_offset = (int)((widgetwidth * 0.5) - (pixbwidth * 0.4));
		
		Gdk.draw_pixbuf(this.window,          //Destination drawable
		                this.style.fg_gc[0],  //a Gdk.GC, used for clipping, or NULL
		                drawing_pb,                 //a Gdk Pixbuf
		                0, 0,                 //Source X/Y coordinates within pixbuf.
		                x_offset,             //Destination X coordinate within drawable
		                y_offset,             //Destination Y coordinate within drawable
		                -1,                   //Width of region to render, in pixels, or -1 to use pixbuf width.
		                -1,                   //Height of region to render, in pixels, or -1 to use pixbuf height.
		                Gdk.RgbDither.NONE,   //Dithering mode for GdkRGB.
		                0, 0                  //X/Y offsets for dither.
		                );
		this.window.end_paint();
		return;
	}                   
		                  
		

	public void trigger_expose() {
		//trigger a redraw by gtk using our expose_event handler
		this.queue_draw_area(0, 0, this.allocation.width, this.allocation.height);
	}
}

