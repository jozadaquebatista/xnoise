/* xnoise-control-button.vala
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
* A ControlButton is a Gtk.Button that initiates playback of the previous or next item or stop
*/
public class Xnoise.ControlButton : Gtk.Button {
	public static enum Direction {
		NEXT = 0,
		PREVIOUS,
		STOP
	}
	
	private unowned Main xn;
	private Direction direction;
	
	public ControlButton(Direction _direction = Direction.STOP) {
		this.xn = Main.instance;
		
		if(_direction != Direction.NEXT && _direction != Direction.PREVIOUS && _direction != Direction.STOP)
			direction = Direction.STOP;
		else
			direction = _direction;
			
		string stockid = STOCK_MEDIA_STOP;
		switch (direction) {
			case Direction.NEXT:
				stockid = STOCK_MEDIA_NEXT;
				break;
			case Direction.PREVIOUS:
				stockid = STOCK_MEDIA_PREVIOUS;
				break;
			case Direction.STOP:
				stockid = STOCK_MEDIA_STOP;
				break;
			default:
				stockid = STOCK_MEDIA_STOP;
				break;
		}
		var img = new Gtk.Image.from_stock(stockid, Gtk.IconSize.SMALL_TOOLBAR);
		this.set_image(img);
		this.relief = Gtk.ReliefStyle.NONE;
		this.can_focus = false;
		this.clicked.connect(this.on_clicked);
	}

	public void on_clicked() {
		if(direction == Direction.NEXT || direction == Direction.PREVIOUS)
			this.xn.main_window.change_song(direction);
		else if(direction == Direction.STOP)
			this.xn.main_window.stop();
	}
}




