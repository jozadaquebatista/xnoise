/* xnoise-misc.vala
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

// GENERAL NAMESPACE FUNCTIONS
namespace Xnoise {
	
	public static Params par;
	
	public static void initialize() {
		par = new Params();
	}
}


// PROJECT WIDE USED INTERFACES AND ENUMS

//Enums

public enum Xnoise.MusicBrowserColumn { //TODO: Rename
	ICON = 0,
	VIS_TEXT,
	ARTIST_ID,
	ALBUM_ID,
	TITLE_ID
}

public enum Xnoise.Repeat { 
	NOT_AT_ALL = 0,
	SINGLE,
	ALL
}

public struct Xnoise.TrackData { // meta information structure
	public string Artist;
	public string Album;
	public string Title;
	public string Genre;
	public uint Tracknumber;
}

public enum Xnoise.TrackListColumn {
	STATE = 0,
	ICON,
	TRACKNUMBER,
	TITLE,
	ALBUM,
	ARTIST,
	URI
}

public enum Xnoise.TrackStatus { //TODO: Rename
	STOPPED = 0,
	PLAYING,
	PAUSED,
	POSITION_FLAG
}

public enum Xnoise.Direction {
	NEXT = 0,
	PREVIOUS,
}


//Interfaces

public interface Xnoise.IParams : GLib.Object {
	public abstract void read_params_data();
	public abstract void write_params_data();
}



