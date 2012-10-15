/* xnoise-album-data.vala
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


// DATA TRANSFER CLASS

/**
 * This class is used to move around media information
 */
namespace Xnoise {
    
    public class AlbumData {
        public string? artist = null;
        public string? album = null;
        
        public string? comment = null;
        public uint year = 0;
        public uint trackcount = 0;
        public Item? item = Item(ItemType.UNKNOWN);
        public int32 dat1 = -1;
        public int32 dat2 = -1;
    }
    
    public static AlbumData copy_albumdata(AlbumData? ad) {
        if(ad == null)
            return new AlbumData();
        AlbumData ad_new = new AlbumData();
        ad_new.artist      = ad.artist;
        ad_new.album       = ad.album;
        ad_new.comment     = ad.comment;
        ad_new.year        = ad.year;
        ad_new.trackcount  = ad.trackcount;
        ad_new.item        = ad.item;
        ad_new.dat1        = ad.dat1;
        ad_new.dat2        = ad.dat2;
        return ad_new;
    }
}

