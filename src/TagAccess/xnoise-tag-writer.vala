/* xnoise-tag-writer.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
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
//  public string? artist = null;
//  public string? album = null;
//  public string? title = null;
//  public string? Genre = null;
//  public uint Year = 0;
//  public uint Tracknumber = 0;
//  public int32 Length = 0;
//  public int Bitrate = 0;
//  public ItemType Mediatype = ItemType.UNKNOWN;
//  public string? Uri = null;
//}


public class Xnoise.TagWriter {
//	public TagWriter() {
//		print("construct TagWriter\n");
//	}
	public bool write_tag(File? file, TrackData? td) {
		// does writes for values that are different from default values
		if(file == null)
			return false;
		if(td == null)
			return false;
		bool retval = false;

		string path = null;
		path = file.get_path();
		if(path == null)
			return false;

		TagLib.File taglib_file = null;
		taglib_file = new TagLib.File(path);
		if(taglib_file != null && taglib_file.is_valid()) {
			unowned TagLib.Tag tag = taglib_file.tag;
			if(t != null) {
				if(td.artist != null && td.artist != "")
					tag.artist = td.artist;
					
				if(td.title != null && td.title != "")
					tag.title = td.title;
				
				if(td.album != null && td.album != "")
					tag.album = td.album;
				
				if(td.genre != null && td.genre != "")
					tag.genre = td.genre;
				
				if(td.year != 0)
					tag.year = td.year;
				
				if(td.tracknumber != 0)
					tag.track = td.tracknumber;
				
				retval = taglib_file.save();
			}
		}
		taglib_file = null;
		return retval;
	}

	public bool write_artist(File? file, string? artist) {
		// does writes for values that are different from default values
		if(file == null)
			return false;
		if(artist == null)
			return false;
		bool retval = false;

		string path = null;
		path = file.get_path();
		if(path == null)
			return false;
		
		TagLib.File taglib_file = null;
		taglib_file = new TagLib.File(path);
		if(taglib_file!=null) {
			unowned TagLib.Tag tag = taglib_file.tag;
			if(t != null) {
				if(artist != "")
					tag.artist = artist;
				else
					return false;
								
				retval = taglib_file.save();
			}
		}
		taglib_file = null;
		return retval;
	}

	public bool write_album(File? file, string? album) {
		// does writes for values that are different from default values
		if(file == null)
			return false;
		if(album == null)
			return false;
		bool retval = false;

		string path = null;
		path = file.get_path();
		if(path == null)
			return false;
		
		TagLib.File taglib_file = null;
		taglib_file = new TagLib.File(path);
		if(taglib_file!=null) {
			unowned TagLib.Tag tag = taglib_file.tag;
			if(t != null) {
				if(album != "")
					tag.album = album;
				else
					return false;
								
				retval = taglib_file.save();
			}
		}
		taglib_file = null;
		return retval;
	}

}

