/* xnoise-media-extensions.vala
 *
 * Copyright (C) 2011-2012  Jörn Magens
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


public class Xnoise.MediaExtensions {
    // known media extensions. for a basic file check from uri/path
    private string[] _list = {
        "mp3", 
        "ogg", 
        "wma",
        "avi",
        "oga",
        "ogv",
        "mpeg",
        "mpg",
        "mov",
        "flac",
        "wav",
        "aiff",
        "m4a",
        "mp4",
        "mp4v",
        "wmv",
        "ts",
        "asx",
        "m3u",
        "xspf",
        "pls",
        "wpl"
    };

    public string[] list {
        get {
            return _list;
        }
    }
    
    // syntax support for 'in'
    public bool contains(string? extension) {
        if(extension == null)
            return false;
        foreach(unowned string s in _list) {
            if(extension == s) return true;
        }
        return false;
    }
}

