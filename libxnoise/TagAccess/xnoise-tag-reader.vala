/* xnoise-tag-reader.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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
    public static TrackData? read_tag(string? filename, bool try_read_image_data = false) {
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
        info = Info.create(f.get_path());
        if(info != null) {
            if(info.load()) {
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
                td.tracknumber    = info.track_number;
                td.length         = info.length;
                td.is_compilation = info.is_compilation;
                td.has_embedded_image = info.has_image;
                td.disk_number    = (info.volume_number < 1 ? 1 : info.volume_number);
                if(try_read_image_data) {
//                    uint8[] data = null;
                    TagInfo.Image[] images;
                    if((images = info.get_images())!=null && images.length > 0) {
//                        if(data != null && data.length > 0) {
                            var pbloader = new Gdk.PixbufLoader();
                            try {
                                pbloader.write(images[0].get_data());
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
//                        }
                    }
                }
            } 
            else {
                td.artist      = UNKNOWN_ARTIST;
                td.title       = UNKNOWN_TITLE;
                td.album       = UNKNOWN_ALBUM;
                td.genre       = UNKNOWN_GENRE;
                td.albumartist = EMPTYSTRING;
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
//            td.year        = 0;
//            td.tracknumber = (uint)0;
//            td.length      = (int32)0;
//            td.bitrate     = 0;
        }
        if(td.title  == UNKNOWN_TITLE)
            td.title = prepare_name_from_filename(GLib.Filename.display_basename(filename));
        
        return td;
    }
}


