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
    public signal void refreshed_stamp(uint32 new_stamp);
    
    protected int source_id;
    internal void set_source_id(int id) {
        source_id = id;
    }
    
    public int get_source_id() {
        return source_id;
    }

    public abstract unowned string get_datasource_name();
    
    public abstract bool get_trackdata_for_uri(ref string? uri, out TrackData val);
    
    public abstract Item[] get_artists(string searchtext,
                                       CollectionSortMode sort_mode,
                                       HashTable<ItemType,Item?>? items);
    
    public abstract TrackData[]? get_trackdata_for_albumartist(string searchtext,
                                                               CollectionSortMode sort_mode,
                                                               HashTable<ItemType,Item?>? items);
    public abstract TrackData[]? get_trackdata_for_artist(string searchtext,
                                                         CollectionSortMode sort_mode,
                                                         HashTable<ItemType,Item?>? items);
    public abstract Item? get_albumartist_item_from_id(string searchtext, int32 id, uint32 stamp);
    
    public abstract TrackData[]? get_trackdata_for_album(string searchtext,
                                                         CollectionSortMode sort_mode,
                                                         HashTable<ItemType,Item?>? items);
    public abstract Item[] get_albums(string searchtext,
                                      CollectionSortMode sort_mode,
                                      HashTable<ItemType,Item?>? items);
    
    public abstract TrackData[] get_trackdata_for_item(string searchterm, Item? item);
    
    public abstract bool get_stream_trackdata_for_item(Item? item, out TrackData td);
    
    public abstract TrackData[]? get_all_tracks(string searchtext);
}

