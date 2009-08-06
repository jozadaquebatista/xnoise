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
	public Gdk.Pixbuf logo_pixbuf;
	private Gdk.Pixbuf logo;
	private Main xn;
	
	public VideoScreen() {
		this.xn = Main.instance();
		try {
			logo_pixbuf = new Gdk.Pixbuf.from_file(Config.UIDIR + "xnoise_logo_big.svg");
		}
		catch(GLib.Error e) {
			print("%s\n", e.message);
		}
	}

	public override bool expose_event(Gdk.EventExpose e) {

		if(e.count > 0) return true; //exposure compression, maybe not needed
			
		Gdk.draw_rectangle(this.window, 
		                   this.style.black_gc, true, 
		                   e.area.x, e.area.y,
		                   e.area.width, e.area.height
		                   );

		if(!xn.gPl.current_has_video) {
			if(this.logo_pixbuf!=null) {
				logo = null;
				int s_width, s_height, w_width, w_height;
				float ratio;
				var region = new Gdk.Region();
				var rect = Gdk.Rectangle();
				rect.x = 0;
				rect.y = 0;
				rect.width = this.allocation.width;
				rect.height = this.allocation.height;
				region = Gdk.Region.rectangle(rect);

				this.window.begin_paint_region(region);

				Gdk.draw_rectangle(this.window, 
						           this.style.black_gc, true, 
						           e.area.x, e.area.y,
						           e.area.width, e.area.height
						           );
						           
				s_width  = logo_pixbuf.get_width();
				s_height = logo_pixbuf.get_height();
				w_width  = this.allocation.width;
				w_height = this.allocation.height;

				if((float)w_width / s_width > (float)w_height / s_height) {
					ratio = (float)w_height / s_height;
				} 
				else {
					ratio = (float)w_width / s_width;
				}

				s_width = (int)(s_width * ratio);
				s_height = (int)(s_height * ratio);

				if(s_width<= 1||s_height<= 1) {
					this.window.end_paint();
					return true;
				}

				logo = logo_pixbuf.scale_simple(s_width, s_height, Gdk.InterpType.BILINEAR);

				Gdk.draw_pixbuf(this.window, this.style.fg_gc[0], 
					            logo, 0, 0, (w_width-s_width)/2, 
					            (w_height-s_height)/2, s_width, 
					            s_height, Gdk.RgbDither.NONE, 
					            0, 0);
				this.window.end_paint();
			} 
			else if(this.window!=null) {
		  		// No pixbuf, just draw a black background then
				this.window.clear_area(0, 0,
					                   this.allocation.width,
					                   this.allocation.height);
			}
		}
		return true;
	}
}

