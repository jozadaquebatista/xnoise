/* xnoise-videoscreen.vala
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

public class Xnoise.VideoScreen : Gtk.DrawingArea {
	public Gdk.Pixbuf logo_pixb;
	private Gdk.Pixbuf logo;
	private Main xn;
	
	public VideoScreen() {
		this.xn = Main.instance();
		init_video_screen();
	}


	private void init_video_screen() {
		this.set_double_buffered(false);
		this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK);
		try {
			logo_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "xnoise_logo_big.svg");
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
			//print("current has no video\n");
			if(this.logo_pixb!=null) {
				logo = null;
				int logowidth, logoheight, widgetwidth, widgetheight;
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
						           
				logowidth  = logo_pixb.get_width();
				logoheight = logo_pixb.get_height();
				widgetwidth  = this.allocation.width;
				widgetheight = this.allocation.height;

				if((float)widgetwidth/logowidth>(float)widgetheight/logoheight) 
					ratio = (float)widgetheight/logoheight;
				else 
					ratio = (float)widgetwidth/logowidth;

				logowidth = (int)(logowidth*ratio);
				logoheight = (int)(logoheight*ratio);

				if(logowidth<=1||logoheight<=1) { 
					// Do not paint for small pictures
					this.window.end_paint();
					return true;
				}

				logo = logo_pixb.scale_simple(logowidth, logoheight, Gdk.InterpType.HYPER);

				Gdk.draw_pixbuf(this.window, this.style.fg_gc[0], 
					            logo, 0, 0, (widgetwidth-logowidth)/2, 
					            (widgetheight-logoheight)/2, logowidth, 
					            logoheight, Gdk.RgbDither.NONE, 
					            0, 0);
				this.window.end_paint();
			} 
			else if(this.window!=null) {
				Gdk.draw_rectangle(this.window, 
						           this.style.black_gc, true, 
						           e.area.x, e.area.y,
						           e.area.width, e.area.height
						           );
			}
		}
		return true;
	}
	
	public void trigger_expose () {
		//TODO: maybe this should be triggered from elsewhere. But
		// I had difficulties to get this via a notify signal in VideoScreen widget
		//TODO: This should only be triggered if logo is not already there.
		//Otherwise there is a flickering
		Gdk.EventExpose e = Gdk.EventExpose();
		e.type = Gdk.EventType.EXPOSE;
		e.window = this.window;
		var rect = Gdk.Rectangle();
		rect.x = 0;
		rect.y = 0;
		rect.width = this.allocation.width;
		rect.height = this.allocation.height;
		e.area = rect;
		Gdk.Region region = Gdk.Region.rectangle(rect);
		e.region = region;
		e.count = 0;
		e.send_event = (char)1;
		this.expose_event(e);
	}
}

