/* xnoise-item-converter.vala
 *
 * Copyright (C) 2011  Jörn Magens
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

public class Xnoise.ItemConverter : Object {

	//this function uses the database so use it in the database thread, only
	public TrackData[]? to_trackdata(Item? item, ref string searchtext) {
		// Take input and convert to tracks
		if(item == null)
			return null;
		
		TrackData[] result = {};
		// Now assuming everything is in db !
		
		switch(item.type) {
			case ItemType.LOCAL_AUDIO_TRACK:
			case ItemType.LOCAL_VIDEO_TRACK:
				if(item.db_id > -1) {
					result = {};//new Array<TrackData>.sized(true, true, sizeof(Item), 1);
					TrackData? tmp = db_browser.get_trackdata_by_titleid(ref searchtext, item.db_id);
					if(tmp == null)
						break;
					result += tmp;
				}
				break;
			case ItemType.COLLECTION_CONTAINER_ALBUM:
				if(item.db_id > -1) {
					result = {};//new Array<TrackData>.sized(true, true, sizeof(Item), 8);
					result = db_browser.get_trackdata_by_albumid(ref searchtext, item.db_id);
					break;
				}
				break;
			case ItemType.COLLECTION_CONTAINER_ARTIST:
				if(item.db_id > -1) {
					result = {};
					result = db_browser.get_trackdata_by_artistid(ref searchtext, item.db_id);
					break;
				}
				break;
			case ItemType.STREAM:
				break;
			case ItemType.PLAYLIST:
				//result.append_val(item);
				break;
			case ItemType.LOCAL_FOLDER:
				//result.append_val(item);
				break;
			case ItemType.COLLECTION_CONTAINER_VIDEO:
				//get all video from db
				break;
			case ItemType.COLLECTION_CONTAINER_STREAM:
				// get all streams from db
				break;
			default:
				break;
		}
		return result;
	}
}
