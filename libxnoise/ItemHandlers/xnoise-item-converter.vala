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
using Xnoise.Playlist;
using Xnoise.Services;
using Xnoise.TagAccess;

public class Xnoise.ItemConverter : Object {

    public TrackData[]? to_trackdata(Item? item, string? searchtext) {
        
        //this function uses the database so use it in the database thread
//        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, null);
        
        if(item == null)
            return null;
        
        if(searchtext == null)
            searchtext = EMPTYSTRING;
        
        TrackData[] result = {};
        
        switch(item.type) {
            case ItemType.LOCAL_AUDIO_TRACK:
            case ItemType.LOCAL_VIDEO_TRACK:
                if(item.db_id > -1 && (int)Linux.gettid() == db_worker.thread_id) {
                    TrackData? tmp = db_reader.get_trackdata_by_titleid(global.searchtext, item.db_id);
                    if(tmp == null)
                        break;
                    result += tmp;
                }
                else if(item.uri != null) {
                    TrackData? tmp = null;
                    if((int)Linux.gettid() == db_worker.thread_id && db_reader.get_trackdata_for_uri(ref item.uri, out tmp)) {
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
                        string artist=EMPTYSTRING, album = EMPTYSTRING, title = EMPTYSTRING, lengthString = EMPTYSTRING, genre = UNKNOWN_GENRE;
                        string? yearString = null;
                        uint tracknumb = 0;
                        File file = File.new_for_uri(item.uri);
                        if(!file.query_exists(null))
                            return null;
                        var tr = new TagReader();
                        var tags = tr.read_tag(file.get_path());
                        if(tags == null) {
                            title = prepare_name_from_filename(file.get_basename());
                        }
                        else {
                            artist         = tags.artist;
                            album          = tags.album;
                            title          = tags.title;
                            tracknumb      = tags.tracknumber;
                            genre          = tags.genre;
                            lengthString = make_time_display_from_seconds(tags.length);
                            if(tags.year > 0) 
                                yearString = "%u".printf(tags.year);
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
                if(item.db_id > -1 && (int)Linux.gettid() == db_worker.thread_id) {
                    result = db_reader.get_trackdata_by_albumid(global.searchtext, item.db_id);
                    break;
                }
                break;
            case ItemType.COLLECTION_CONTAINER_ARTIST:
                if(item.db_id > -1 && (int)Linux.gettid() == db_worker.thread_id) {
                    result = db_reader.get_trackdata_by_artistid(global.searchtext, item.db_id);
                    break;
                }
                break;
            case ItemType.STREAM:
                var tmp = new TrackData();
                if(item.db_id > -1) {
                    if((int)Linux.gettid() == db_worker.thread_id && db_reader.get_stream_td_for_id(item.db_id, out tmp)) {
                        result += tmp;
                        return result;
                    }
                }
                //else {
                //    print("itemtype.stream\n");
                //}
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
