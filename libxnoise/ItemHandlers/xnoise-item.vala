/* xnoise-item.vala
 *
 * Copyright (C) 2011, 2013  Jörn Magens
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


namespace Xnoise {
    public struct Item { // TODO: use db id for artist album track
        public Item(ItemType _type = ItemType.UNKNOWN, string? _uri = null, int32 _db_id = -1) {
            this.type  = _type;
            this.db_id = _db_id;
            this.uri   = _uri;
        }
        public ItemType type;
        public uint32    stamp;      // db import state
        public int32     db_id;      // the id in the database or -1
        public string?   uri;        // uri of item
        public string?   text;       // some text for any purpose
        public string?   text2;      // some text for any purpose
        public int       source_id;  // data source id refering to Xnoise.DataSource
    }

    public enum ItemType {
        UNKNOWN = 0,
        LOCAL_AUDIO_TRACK,
        LOCAL_VIDEO_TRACK,
        STREAM,
        CDROM_TRACK,                         // not possible, yet
        PLAYLIST,                            // item can be converted
        LOCAL_FOLDER,                        // item can be converted
        COLLECTION_CONTAINER_ALBUMARTIST,    // item can be converted
        COLLECTION_CONTAINER_ARTIST,         // item can be converted
        COLLECTION_CONTAINER_ALBUM,          // item can be converted
        COLLECTION_CONTAINER_GENRE,          // item can be converted
        COLLECTION_CONTAINER_YEAR,           // item can be converted
        LOADER//,
        //CUSTOM_DATA_COL_ID
        //to be extended
    }
}
