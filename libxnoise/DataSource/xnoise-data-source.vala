/* xnoise-data-source.vala
 *
 * Copyright (C) 2012  Jörn Magens
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




public abstract class Xnoise.DataSource : GLib.Object {
    
    public abstract bool get_trackdata_for_uri(ref string? uri, out TrackData val);
    
    public abstract Item[] get_artists_with_search(string searchtext);
    public abstract TrackData[]? get_trackdata_by_artistid(string searchtext, int32 id);
    public abstract Item? get_artistitem_by_artistid(string searchtext, int32 id);
    
    public abstract TrackData[]? get_trackdata_by_albumid(string searchtext, int32 id);
    public abstract Item[] get_albums_with_search(string searchtext, int32 id);
    
    public abstract TrackData? get_trackdata_by_titleid(string searchtext, int32 id);
    
}

