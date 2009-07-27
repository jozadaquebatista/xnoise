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
		TrackData tags; 
		TagLib.File taglib_file = null;
		taglib_file = new TagLib.File(file);
		if(taglib_file!=null) {
			weak TagLib.Tag t = taglib_file.tag; 
			tags = TrackData();
			try {
				tags.Artist = t.artist;
				tags.Title = t.title;
				tags.Album = t.album;
				tags.Genre = t.genre;
				tags.Tracknumber = t.track;
			}
			finally {
				if((tags.Artist == "")||(tags.Artist == null)) tags.Artist = "unknown artist";
				if((tags.Title  == "")||(tags.Title  == null)) tags.Title  = "unknown title";
				if((tags.Album  == "")||(tags.Album  == null)) tags.Album  = "unknown album";
				if((tags.Genre  == "")||(tags.Genre  == null)) tags.Genre  = "unknown genre";
				t = null;
				taglib_file = null;
			}
		}
		else {
			tags = TrackData(); 
			tags.Artist = "unknown artist";
			tags.Title  = "unknown title";
			tags.Album  = "unknown album";
			tags.Genre  = "unknown genre";
			tags.Tracknumber = (uint)0;
		}
		
		if(tags.Title  == "unknown title") {
			tags.Title = GLib.Filename.display_basename(file);
		}
		return tags;
	}
}

