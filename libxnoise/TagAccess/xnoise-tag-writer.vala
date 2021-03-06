/* xnoise-tag-writer.vala
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

using TagInfo;


public class Xnoise.TagAccess.TagWriter {
    public static bool write_tag(File? file, TrackData? td, bool read_before_write = false) {
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
        
        Info info = null;
        info = TagInfo.Info.create(path);
        
        if(info != null) {
            if(read_before_write)
                info.load();
            
            info.artist       = td.artist      != null ? td.artist      : EMPTYSTRING;
            info.title        = td.title       != null ? td.title       : EMPTYSTRING;
            info.album        = td.album       != null ? td.album       : EMPTYSTRING;
            info.albumartist  = td.albumartist != null ? td.albumartist : EMPTYSTRING;
            info.genre        = td.genre       != null ? td.genre       : EMPTYSTRING;
            if(td.year < 0)
                td.year = 0;
            info.year = (int)td.year;
            
            if(td.tracknumber < 0)
                td.tracknumber = 0;
            info.track_number = (int)td.tracknumber;
            
            if(td.disk_number < 1)
                td.disk_number = 1;
            info.volume_number = (int)td.disk_number;
            
            info.is_compilation  = td.is_compilation;
            
            retval = info.save();
        }
        return retval;
    }

    public static bool remove_compilation_flag(File? file) {
        if(file == null)
            return false;
        
        bool retval = false;
        
        string path = null;
        path = file.get_path();
        if(path == null)
            return false;
        
        Info info = null;
        info = Info.create(path);
        
        if(info != null) {
            info.is_compilation  = false;
            retval = info.save();
        }
        return retval;
    }

//    public bool write_artist(File? file, string? artist) {
//        // does writes for values that are different from default values
//        if(file == null)
//            return false;
//        if(artist == null)
//            return false;
//        bool retval = false;
//        
//        string path = null;
//        path = file.get_path();
//        if(path == null)
//            return false;
//        
//        Info info = null;
//        info = Info.factory_make(path);
//        
//        if(info != null) {
//            info.read();
//            info.artist = artist != null ? artist : EMPTYSTRING;
//            
//            retval = info.write();
//        }
//        return retval;
//    }

//    public bool write_genre(File? file, string? genre) {
//        // does writes for values that are different from default values
//        if(file == null)
//            return false;
//        if(genre == null)
//            return false;
//        bool retval = false;
//        
//        string path = null;
//        path = file.get_path();
//        if(path == null)
//            return false;
//        
//        Info info = null;
//        info = Info.factory_make(path);
//        
//        if(info != null) {
//            info.read();
//            info.genre = genre != null ? genre : EMPTYSTRING;
//            
//            retval = info.write();
//        }
//        return retval;
//    }

//    public bool write_album(File? file, string? album) {
//        // does writes for values that are different from default values
//        if(file == null)
//            return false;
//        if(album == null)
//            return false;
//        bool retval = false;

//        string path = null;
//        path = file.get_path();
//        if(path == null)
//            return false;
//        
//        Info info = null;
//        info = Info.factory_make(path);
//        
//        if(info != null) {
//            info.read();
//            info.album = album != null ? album : EMPTYSTRING;
//            
//            retval = info.write();
//        }
//        return retval;
//    }

//    public bool write_year(File? file, uint year) {
//        // does writes for values that are different from default values
//        if(file == null)
//            return false;
////        if(album == null)
////            return false;
//        bool retval = false;

//        string path = null;
//        path = file.get_path();
//        if(path == null)
//            return false;
//        
//        Info info = null;
//        info = Info.factory_make(path);
//        
//        if(info != null) {
//            info.read();
//            info.year = (int)year;
//            
//            retval = info.write();
//        }
//        return retval;
//    }
}

