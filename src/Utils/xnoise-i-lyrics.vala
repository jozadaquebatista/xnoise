/* xnoise-i-lyrics.vala
 *
 * Copyright (C) 2011  Jörn Magens
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


/**
 * ILyrics implementors should be asynchronously look for lyrics
 * The reply is checked for matching artist/title
 */
public interface Xnoise.ILyrics : GLib.Object {
	public abstract void find_lyrics();
	public abstract string get_identifier();
	public abstract string get_credits();
	public abstract uint get_timeout(); // id of the GLib.Source of the timeout for the search
	
	
	// DEFAULT IMPLEMENTATIONS
	
	protected bool timeout_elapsed() { 
		Timeout.add_seconds(1, () => {
			this.destruct();
			return false;
		});
		return false;
	}
	
	// ILyrics implementor have to call destruct after signalling the arrival of a new lyrics text
	public void destruct() { // default implementation of explizit destructor
		Idle.add( () => {
			if(get_timeout() != 0)
				Source.remove(get_timeout());
			ILyrics* p = this;
			delete p;
			return false;
		});
	}
}



