/* xnoise-item-converter.vala
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

using Xnoise;
using Xnoise.Resources;
using Xnoise.Playlist;
using Xnoise.Utilities;
using Xnoise.TagAccess;

public class Xnoise.ItemConverter : Object {

    public TrackData[]? to_trackdata(Item? item, string? searchtext) {
        
        //this function uses the database so use it in the database thread
        
        if(item == null)
            return null;
        
        if(searchtext == null)
            searchtext = EMPTYSTRING;
        
        TrackData[] result = {};
        
        switch(item.type) {
            case ItemType.LOCAL_AUDIO_TRACK:
            case ItemType.LOCAL_VIDEO_TRACK:
                if(item.db_id > -1 && db_worker.is_same_thread()) {
                    DataSource ds = get_data_source(item.source_id);
                    assert(ds != null);
                    return_val_if_fail(get_current_stamp(ds.get_source_id()) == item.stamp, null);
                    TrackData? tmp = ds.get_trackdata_for_item(item);
                    if(tmp == null)
                        break;
                    result += tmp;
                }
                else if(item.uri != null) {
                    TrackData? tmp = null;
                    DataSource ds = get_data_source(item.source_id);
                    assert(ds != null);
                    return_val_if_fail(get_current_stamp(ds.get_source_id()) == item.stamp, null);
                    if(db_worker.is_same_thread() && ds.get_trackdata_for_uri(ref item.uri, out tmp)) {
                        if(tmp != null) {
                            if(tmp.item.type == ItemType.UNKNOWN)
                                tmp.item.type = ItemHandlerManager.create_item(item.uri).type;
                            if(tmp.item.type != ItemType.UNKNOWN)
                                result += tmp;
                        }
                        else {
                            return null;
                        }
                    }
                    else {
                        print("Using tag reader in item converter.\n");
                        File file = File.new_for_uri(item.uri);
                        if(!file.query_exists(null))
                            return null;
                        var tr = new TagReader();
                        TrackData? tags = tr.read_tag(file.get_path());
                        if(tags == null) {
                            tags = new TrackData();
                            tags.title = prepare_name_from_filename(file.get_basename());
                        }
                        tags.item = item;
                        result += tags;
                    }
                }
                else {
                    return null;
                }
                break;
            case ItemType.COLLECTION_CONTAINER_ALBUM:
                if(item.db_id > -1 && db_worker.is_same_thread()) {
                    DataSource ds = get_data_source(item.source_id);
                    assert(ds != null);
                    return_val_if_fail(get_current_stamp(ds.get_source_id()) == item.stamp, null);
                    result = ds.get_trackdata_by_albumid(global.searchtext, item.db_id, item.stamp);
                    break;
                }
                break;
            case ItemType.COLLECTION_CONTAINER_ARTIST:
                if(item.db_id > -1 && db_worker.is_same_thread()) {
                    DataSource ds = get_data_source(item.source_id);
                    assert(ds != null);
                    return_val_if_fail(get_current_stamp(ds.get_source_id()) == item.stamp, null);
                    result = ds.get_trackdata_by_artistid(global.searchtext, item.db_id, item.stamp);
                    break;
                }
                break;
            case ItemType.STREAM:
                var tmp = new TrackData();
                //print("CONV STREAM %d\n", item.source_id);
                DataSource ds = get_data_source(item.source_id);
                assert(ds != null);
                return_val_if_fail(get_current_stamp(ds.get_source_id()) == item.stamp, null);
                if(item.db_id > -1) {
                    if(db_worker.is_same_thread() && ds.get_stream_trackdata_for_item(item, out tmp)) {
                        result += tmp;
                        return result;
                    }
                }
                else {
                    print("DBID is -1\n");
                }
                tmp.item = item;
                File ft = File.new_for_uri(item.uri);
                tmp.title = prepare_name_from_filename(ft.get_basename());
                result += tmp;
                return result;
            case ItemType.PLAYLIST:
                var pr = new Playlist.Reader();
                Playlist.Result rslt;
                if(item.uri == null) {
                    print("no uri for playlist!\n");
                    return null;
                }
                try {
                    rslt = pr.read(item.uri , null);
                }
                catch(Playlist.ReaderError e) {
                    print("Item Converter: %s\n", e.message);
                    return null;
                }
                if(rslt != Playlist.Result.SUCCESS)
                    return null;
                EntryCollection ec = pr.data_collection;
                if(ec != null) {
                    foreach(Entry e in ec) {
                        var tmp = new TrackData();
                        tmp.title  = (e.get_title()  != null ? e.get_title()  : UNKNOWN_TITLE);
                        tmp.album  = (e.get_album()  != null ? e.get_album()  : UNKNOWN_ALBUM);
                        tmp.artist = (e.get_author() != null ? e.get_author() : UNKNOWN_ARTIST);
                        tmp.genre  = (e.get_genre()  != null ? e.get_genre()  : UNKNOWN_GENRE);
                        tmp.item   = ItemHandlerManager.create_item(e.get_uri());
                        //print("conv :%s\n", tmp.item.uri);
                        result += tmp;
                    }
                    break;
                }
                else {
                    return null;
                }
            case ItemType.LOCAL_FOLDER:
                break;
            default:
                break;
        }
        return result;
    }
}
