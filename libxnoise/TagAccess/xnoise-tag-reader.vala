/* xnoise-tag-reader.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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

using Xnoise;
using Xnoise.Services;

public class Xnoise.TagAccess.TagReader {
	public TrackData? read_tag(string? filename) {
		if(filename == null || filename.strip() == EMPTYSTRING)
			return null;
		File f = null;
		f = File.new_for_path(filename);
		if(f == null)
			return null;
		TrackData td = new TrackData();
		td.item = ItemHandlerManager.create_item(f.get_uri());
		TagLib.File taglib_file = null;
		if(td.item.type != ItemType.LOCAL_AUDIO_TRACK && td.item.type != ItemType.LOCAL_VIDEO_TRACK)
			return null;
		if(f.get_path() == null)
			return null;
		taglib_file = new TagLib.File(f.get_path());
		if(taglib_file != null && taglib_file.is_valid()) {
			unowned TagLib.Tag tag = null;
			tag = taglib_file.tag;
			unowned TagLib.AudioProperties ap = null;
			ap = taglib_file.audioproperties;
			if(tag != null && ap != null) {
				try {
					// from class Tag
					if(tag != null) {
						if(tag.artist.validate())
						td.artist      = tag.artist;
						td.title       = tag.title;
						td.album       = tag.album;
						td.genre       = tag.genre;
						td.year        = tag.year;
						td.tracknumber = tag.track;
					} 
					else {
						td.artist      = UNKNOWN_ARTIST;
						td.title       = UNKNOWN_TITLE;
						td.album       = UNKNOWN_ALBUM;
						td.genre       = UNKNOWN_GENRE;
						td.year        = 0;
						td.tracknumber = (uint)0;
					}	
					// from class AudioProperties
					if(ap != null) {
						td.length      = (int32)ap.length;
						td.bitrate     = ap.bitrate;
					} else {
						td.length = (int32)0;
						td.bitrate = 0;
					}		
				}
				finally {
					if((td.artist == EMPTYSTRING)||(td.artist == null)) td.artist = UNKNOWN_ARTIST;
					if((td.title  == EMPTYSTRING)||(td.title  == null)) td.title  = UNKNOWN_TITLE;
					if((td.album  == EMPTYSTRING)||(td.album  == null)) td.album  = UNKNOWN_ALBUM;
					if((td.genre  == EMPTYSTRING)||(td.genre  == null)) td.genre  = UNKNOWN_GENRE;
					tag = null;
					taglib_file = null;
				}
			}
			else {
				td.artist      = UNKNOWN_ARTIST;
				td.title       = UNKNOWN_TITLE;
				td.album       = UNKNOWN_ALBUM;
				td.genre       = UNKNOWN_GENRE;
				td.year        = 0;
				td.tracknumber = (uint)0;
				td.length      = (int32)0;
				td.bitrate     = 0;
			}
		}
		else {
			td.artist      = UNKNOWN_ARTIST;
			td.title       = UNKNOWN_TITLE;
			td.album       = UNKNOWN_ALBUM;
			td.genre       = UNKNOWN_GENRE;
			td.year        = 0;
			td.tracknumber = (uint)0;
			td.length      = (int32)0;
			td.bitrate     = 0;
		}
		if(td.title  == UNKNOWN_TITLE)
			td.title = prepare_name_from_filename(GLib.Filename.display_basename(filename));
		
		return (owned)td;
	}
}

