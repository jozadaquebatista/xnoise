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
 *     Jörn Magens
 */

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;

using TagInfo;


public class Xnoise.TagAccess.TagReader {
    public TrackData? read_tag(string? filename, bool try_read_image_data = false) {
        if(filename == null || filename.strip() == EMPTYSTRING)
            return null;
        File f = null;
        f = File.new_for_path(filename);
        if(f == null)
            return null;
        TrackData td = new TrackData();
        td.item = ItemHandlerManager.create_item(f.get_uri());
        Info info = null;
        if(td.item.type != ItemType.LOCAL_AUDIO_TRACK && td.item.type != ItemType.LOCAL_VIDEO_TRACK)
            return null;
        if(f.get_path() == null)
            return null;
        info = Info.factory_make(f.get_path());
        if(info != null) {
            if(info.read()) {
                td.artist         = info.artist != null && info.artist != EMPTYSTRING ?
                                        info.artist : UNKNOWN_ARTIST;
                td.albumartist    = info.albumartist != null ?
                                        info.albumartist : EMPTYSTRING;
                td.title          = info.title != null && info.title != EMPTYSTRING ?
                                        info.title : UNKNOWN_TITLE;
                td.album          = info.album != null && info.album != EMPTYSTRING ?
                                        info.album : UNKNOWN_ALBUM;
                td.genre          = info.genre != null && info.genre != EMPTYSTRING ?
                                        info.genre : UNKNOWN_GENRE;
                td.year           = info.year;
                td.tracknumber    = info.tracknumber;
                td.length         = info.length;
                td.is_compilation = info.is_compilation;
                td.has_embedded_image = info.has_image;
                td.cd_number_str  = EMPTYSTRING;
                if(try_read_image_data) {
                    uint8[] data = null;
                    TagInfo.ImageType image_type;
                    if(info.get_image(out data, out image_type)) {
                        if(data != null && data.length > 0) {
                            var pbloader = new Gdk.PixbufLoader();
                            try {
                                pbloader.write(data);
                            }
                            catch(Error e) {
                                print("Error 1: %s\n", e.message);
                                try { pbloader.close(); } catch(Error e) { print("Error 2\n");}
                            }
                            try { 
                                pbloader.close(); 
                                td.pixbuf = pbloader.get_pixbuf();
                            } 
                            catch(Error e) { 
                                print("Error 3 for %s :\n\t %s\n", f.get_path(), e.message);
                            }
                        }
                    }
                }
            } 
            else {
                td.artist      = UNKNOWN_ARTIST;
                td.title       = UNKNOWN_TITLE;
                td.album       = UNKNOWN_ALBUM;
                td.genre       = UNKNOWN_GENRE;
                td.albumartist = EMPTYSTRING;
                td.cd_number_str  = EMPTYSTRING;
//                td.year        = 0;
//                td.tracknumber = (uint)0;
//                td.length      = 0;//(int32)ap.length;
            }
        }
        else {
            td.artist      = UNKNOWN_ARTIST;
            td.title       = UNKNOWN_TITLE;
            td.album       = UNKNOWN_ALBUM;
            td.genre       = UNKNOWN_GENRE;
            td.albumartist = EMPTYSTRING;
            td.cd_number_str  = EMPTYSTRING;
//            td.year        = 0;
//            td.tracknumber = (uint)0;
//            td.length      = (int32)0;
//            td.bitrate     = 0;
        }
        if(td.title  == UNKNOWN_TITLE)
            td.title = prepare_name_from_filename(GLib.Filename.display_basename(filename));
        
        return (owned)td;
    }
}


/*

using Gst;

public class Xnoise.TagAccess.TagReader {
    private static Gst.Discoverer d;
    
    public TagReader() {
        if(d == null) {
            try {
                d = new Gst.Discoverer((ClockTime)(1 * Gst.SECOND));
            }
            catch (Error e) {
                print("TagReader could not create Gst.Discoverer: %s\n", e.message);
            }
        }
    }

    public TrackData? read_tag (string filename) {
        if(filename == null || filename.strip() == EMPTYSTRING)
            return null;
        File f = null;
        f = File.new_for_path(filename);
        if(f == null)
            return null;
        TrackData td = new TrackData();
        td.item = ItemHandlerManager.create_item(f.get_uri());
        DiscovererInfo? info = null;
        try {
            info = d.discover_uri(f.get_uri());
        }
        catch(Error e) {
            print("%s\n", e.message);
            return null;
        }
        
        if(info != null && info.get_tags() != null) {
            
            uint bitrate;
            GLib.Date? date = null;
            unowned Gst.TagList? tag_list = info.get_tags();
            if(tag_list == null) {
                //print("tag_list is null for %s\n", f.get_uri());
                return null;
            }
            
            if(!tag_list.get_string(TAG_TITLE, out td.title))
                td.title = UNKNOWN_TITLE;
            if(!tag_list.get_string(TAG_ALBUM, out td.album))
                td.album = UNKNOWN_ALBUM;
            if(!tag_list.get_string(TAG_ARTIST, out td.artist))
                td.artist = UNKNOWN_ARTIST;
            if(!tag_list.get_string(TAG_GENRE, out td.genre))
                td.genre = UNKNOWN_GENRE;
            if(!tag_list.get_uint(TAG_TRACK_NUMBER, out td.tracknumber))
                td.tracknumber = 0;
            if(tag_list.get_date(TAG_DATE, out date)) {
                if(date != null)
                    td.year = (int)date.get_year();
            }
            else {
                td.year = 0;
            }
            if(tag_list.get_uint(TAG_BITRATE, out bitrate))
                td.bitrate = (int)(bitrate/1000);
            else
                td.bitrate = 0;
            
            uint64 duration = info.get_duration();
            if (duration == 0)
                tag_list.get_uint64(TAG_DURATION, out duration);
            
            td.length = (int32)((duration / Gst.SECOND));
            
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



*/

