/* xnoise-tag-writer.vala
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

	// Track meta information class, as defined in xnoise-misc.vala
	//public class Xnoise.TrackData {
	//  public string? Artist = null;
	//  public string? Album = null;
	//  public string? Title = null;
	//  public string? Genre = null;
	//  public uint Year = 0;
	//  public uint Tracknumber = 0;
	//  public int32 Length = 0;
	//  public int Bitrate = 0;
	//  public MediaType Mediatype = MediaType.UNKNOWN;
	//  public string? Uri = null;
	//}


public class Xnoise.TagWriter {
//	public TagWriter() {
//		print("construct TagWriter\n");
//	}
	public bool write_tag(string filename, TrackData? td) {
		if(td == null)
			return false;
		bool retval = false;
		TagLib.File taglib_file = null;
		taglib_file = new TagLib.File(filename);
		if(taglib_file!=null) {
			unowned TagLib.Tag t = taglib_file.tag;
			if(t != null) {
				if(td.Artist != null && td.Artist != "")
					t.artist = td.Artist;
					
				if(td.Title != null && td.Title != "")
					t.title = td.Title;
				
				if(td.Album != null && td.Album != "")
					t.album = td.Album;
				
				if(td.Genre != null && td.Genre != "")
					t.genre = td.Genre;
				
				if(td.Year != 0)
					t.year = td.Year;
				
				if(td.Tracknumber != 0)
					t.track = td.Tracknumber;
				
				retval = taglib_file.save();
			}
		}
		taglib_file = null;
		return retval;
	}
}

