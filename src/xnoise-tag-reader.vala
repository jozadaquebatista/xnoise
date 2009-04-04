/* xnoise-tag-reader.vala
 *
 * Copyright (C) 2009  Jörn Magens
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Jörn Magens
 */

//This class is a connection to taglib_c

using GLib;

public class Xnoise.TagReader : GLib.Object {

	public TrackData read_tag_from_file(string file) {
		TrackData tags; 
		TagLib.File taglib_file = new TagLib.File(file);
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
				if ((tags.Artist == "")||(tags.Artist == null)) tags.Artist = "unknown artist";
				if ((tags.Title  == "")||(tags.Title  == null)) tags.Title  = "unknown title";
				if ((tags.Album  == "")||(tags.Album  == null)) tags.Album  = "unknown album";
				if ((tags.Genre  == "")||(tags.Genre  == null)) tags.Genre  = "unknown genre";
				t = null;
				taglib_file = null;
			}
		}
		else {
			tags = TrackData(); 
			tags.Artist = "unknown artist";
			tags.Title = "unknown title";
			tags.Album = "unknown album";
			tags.Genre = "unknown genre";
			tags.Tracknumber = (uint)0;
		}
		int count = 0;
		if(tags.Artist == "unknown artist") count++;
		if(tags.Title  == "unknown title")  count++;
		if(tags.Album  == "unknown album")  count++;
		if(count==3) {
			string fileBasename = GLib.Filename.display_basename(file);
			tags.Title = fileBasename;
		}
		return tags;
	}
}

