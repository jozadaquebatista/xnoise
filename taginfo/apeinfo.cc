/* Original Author 2008-2012: J.Rios
 * 
 * Edited by: Jörn Magens <shuerhaaken@googlemail.com>
 * 
 * 
 * This Program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This Program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file LICENSE.  If not, write to
 * the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 * http://www.gnu.org/copyleft/gpl.html
 */

#include "ape.h"
#include "ape_internal.h"
#include "taginfo.h"
#include "taginfo_internal.h"


using namespace TagInfo;
using namespace TagInfo::Ape;


ApeInfo::ApeInfo(const string &filename) : Info(), ape_file(filename) {
}


ApeInfo::~ApeInfo() {
}


bool ApeInfo::read(void) {


    ApeTag * Tag = ape_file.get_tag();
    if(Tag) {
            //cout << "title:  " << Tag->get_title()   << endl <<
        //"artist: " << Tag->get_artist()  << endl;
        track_name = Tag->get_title();
        artist = Tag->get_artist();
        album = Tag->get_album();
        genre = Tag->get_genre();
        tracknumber = Tag->get_tracknumber();
        year = Tag->get_year();
        length_seconds = ape_file.get_length();
        bitrate = ape_file.get_bitrate();
        
        comments = Tag->get_item_value(APE_TAG_COMMENT);
        composer = Tag->get_item_value(APE_TAG_COMPOSER);
        disk_str = Tag->get_item_value(APE_TAG_MEDIA);
        album_artist = Tag->get_item_value(APE_TAG_ALBUMARTIST);
        
        if(album_artist.isEmpty())
            album_artist = Tag->get_item_value("AlbumArtist");
        
        return true;
    }
    else {
            printf("Error: Ape file with no tags found\n");
    }
    return false;
}


bool ApeInfo::write(const int changedflag) {
    ApeTag * Tag = ape_file.get_tag();
    if(Tag && (changedflag & CHANGED_DATA_TAGS)) {
        Tag->set_title(track_name);
        Tag->set_artist(artist);
        Tag->set_album(album);
        Tag->set_genre(genre);
        Tag->set_tracknumber(tracknumber);
        Tag->set_year(year);
        Tag->set_item(APE_TAG_COMMENT, comments);
        Tag->set_item(APE_TAG_COMPOSER, composer);
        Tag->set_item(APE_TAG_MEDIA, disk_str);
        Tag->set_item(APE_TAG_ALBUMARTIST, album_artist);
        ape_file.write_tag();
        return true;
    }
    return false;
}


bool ApeInfo::can_handle_lyrics(void) {
    return true;
}


String ApeInfo::get_lyrics(void) {
    ApeTag * Tag = ape_file.get_tag();
    if(Tag)
        return Tag->get_item_value(APE_TAG_LYRICS);
    return "";
}


bool ApeInfo::set_lyrics(const String &lyrics) {
    ApeTag * Tag = ape_file.get_tag();
    if(Tag) {
            Tag->set_item(APE_TAG_LYRICS, lyrics);
        return ape_file.write_tag();
    }
    return false;
}



