/* xnoise-text-column.vala
 *
 * Copyright (C) 2010 Jörn Magens
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

public class Xnoise.TextColumn : TreeViewColumn {
	private int last_size = 0;
	private TrackListModel.Column _id;
	private unowned Main xn;
	
	public TrackListModel.Column id { 
		get {
			return _id;
		}
	}
	
	public signal void resized(bool grow, int delta, TrackListModel.Column source_id);
	
	public TextColumn(string title, CellRendererText renderer, TrackListModel.Column col_id) {
		xn = Main.instance;
		this.set_title(title);
		this._id = col_id;
		this.pack_start(renderer, true);
		this.last_size = this.width;
		this.notify["width"].connect( (s, p) => {
			if(last_size != this.width) {
				bool grow = (this.width > last_size);
				int delta = (this.width - last_size).abs();
				last_size = this.width;
				resized(grow, delta, this.id); //emit signal
			}
		});
	}
	
	// this function sets the size without emmiting the resized signal
	public void adjust_width(int width) {
		last_size = width;
		if(width > this.min_width)
			this.set_fixed_width(width);
		else
			this.set_fixed_width(this.min_width); 
	}
}
