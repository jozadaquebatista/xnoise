/* xnoise-tag-reader.vala
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


internal class Xnoise.TagReader : GLib.Object {

	public TrackData read_tag_from_file(string file) {
		TrackData td; 
		TagLib.File taglib_file = null;
		taglib_file = new TagLib.File(file);
		if(taglib_file!=null) {
			weak TagLib.Tag t = taglib_file.tag; 
			td = TrackData();
			try {
				td.Artist = t.artist;
				td.Title = t.title;
				td.Album = t.album;
				td.Genre = t.genre;
				td.Tracknumber = t.track;
				td.Mediatype   = MediaType.AUDIO;
			}
			finally {
				if((td.Artist == "")||(td.Artist == null)) td.Artist = "unknown artist";
				if((td.Title  == "")||(td.Title  == null)) td.Title  = "unknown title";
				if((td.Album  == "")||(td.Album  == null)) td.Album  = "unknown album";
				if((td.Genre  == "")||(td.Genre  == null)) td.Genre  = "unknown genre";
				t = null;
				taglib_file = null;
			}
		}
		else {
			td = TrackData(); 
			td.Artist = "unknown artist";
			td.Title  = "unknown title";
			td.Album  = "unknown album";
			td.Genre  = "unknown genre";
			td.Tracknumber = (uint)0;
			td.Mediatype   = MediaType.UNKNOWN;
		}
		
		if(td.Title  == "unknown title") {
			td.Title = GLib.Filename.display_basename(file);
		}
		return td;
	}
}

