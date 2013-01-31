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


#include "taginfo.h"
#include "taginfo_internal.h"


using namespace TagInfo;



Mp4Info::Mp4Info(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull()) {
            m_Mp4Tag = ((TagLib::MP4::File *) taglib_file->file())->tag();
    }
    else
        m_Mp4Tag = NULL;
}


Mp4Info::~Mp4Info() {
}


bool Mp4Info::read(void) {
    if(Info::read()) {
        if(m_Mp4Tag) {
            if(m_Mp4Tag->itemListMap().contains("aART")) {
                album_artist = m_Mp4Tag->itemListMap()["aART"].toStringList().front();
            }
            if(m_Mp4Tag->itemListMap().contains("\xA9wrt")) {
                composer = m_Mp4Tag->itemListMap()["\xa9wrt"].toStringList().front();
            }
            if(m_Mp4Tag->itemListMap().contains("disk")) {
                char* c_disk_str;
                if(asprintf(&c_disk_str, "%i/%i", m_Mp4Tag->itemListMap()["disk"].toIntPair().first,
                                                m_Mp4Tag->itemListMap()["disk"].toIntPair().second) >= 0) {
                    disk_str = c_disk_str;
                    free(c_disk_str);
                }
//                disk_str = wxString::Format(wxT("%i/%i"),
//                    m_Mp4Tag->itemListMap()["disk"].toIntPair().first,
//                    m_Mp4Tag->itemListMap()["disk"].toIntPair().second);

            }
            if(m_Mp4Tag->itemListMap().contains("cpil")) {
                is_compilation = m_Mp4Tag->itemListMap()["cpil"].toBool();
            }
            // Rating
            if(m_Mp4Tag->itemListMap().contains("----:com.apple.iTunes:RATING")) {
                long Rating = 0;
                Rating = atol(m_Mp4Tag->itemListMap()["----:com.apple.iTunes:RATING"].toStringList().front().toCString(true));
                if(Rating)
                {
                    if(Rating > 5)
                    {
                        rating = popularity_to_rating(Rating);
                    }
                    else
                    {
                        rating = Rating;
                    }
                }
            }
            if(m_Mp4Tag->itemListMap().contains("----:com.apple.iTunes:PLAY_COUNTER")) {
                long PlayCount = 0;
                PlayCount = atol(m_Mp4Tag->itemListMap()["----:com.apple.iTunes:PLAY_COUNTER"].toStringList().front().toCString(true));
                playcount = PlayCount;
            }
            // Labels
            if(track_labels.size() == 0) {
                if(m_Mp4Tag->itemListMap().contains("----:com.apple.iTunes:TRACK_LABELS"))
                {
                    track_labels_str = m_Mp4Tag->itemListMap()["----:com.apple.iTunes:TRACK_LABELS"].toStringList().front();
                    track_labels = split(track_labels_str, "|");
                }
            }
            if(artist_labels.size() == 0) {
                if(m_Mp4Tag->itemListMap().contains("----:com.apple.iTunes:ARTIST_LABELS"))
                {
                    artist_labels_str = m_Mp4Tag->itemListMap()["----:com.apple.iTunes:ARTIST_LABELS"].toStringList().front();
                    artist_labels = split(artist_labels_str, "|");
                }
            }
            if(album_labels.size() == 0) {
                if(m_Mp4Tag->itemListMap().contains("----:com.apple.iTunes:ALBUM_LABELS"))
                {
                    album_labels_str = m_Mp4Tag->itemListMap()["----:com.apple.iTunes:ALBUM_LABELS"].toStringList().front();
                    album_labels = split(album_labels_str, "|");
                }
            }
            if(m_Mp4Tag->itemListMap().contains("covr")) {
                TagLib::MP4::CoverArtList covers = m_Mp4Tag->itemListMap()[ "covr" ].toCoverArtList();
                has_image = (covers.size() > 0);
            }
            return true;
        }
    }
    return false;
}


void mp4_check_label_frame(TagLib::MP4::Tag * mp4tag, const char * description, const String &value) {
    //guLogMessage(wxT("USERTEXT[ %s ] = '%s'"), wxString(description, wxConvISO8859_1).c_str(), value.c_str());
    if(mp4tag->itemListMap().contains(description)) {
            if(!value.isEmpty()) {
            mp4tag->itemListMap()[ description ] = TagLib::MP4::Item(TagLib::StringList(value));
        }
        else {
            mp4tag->itemListMap().erase(description);
        }
    }
    else {
            if(!value.isEmpty()) {
            mp4tag->itemListMap().insert(description, TagLib::MP4::Item(TagLib::StringList(value)));
        }
    }
}


bool Mp4Info::write(const int changedflag) {
    if(m_Mp4Tag) {
        if(changedflag & CHANGED_DATA_TAGS) {
            m_Mp4Tag->itemListMap()["aART"] = TagLib::StringList(album_artist);
            m_Mp4Tag->itemListMap()["\xA9wrt"] = TagLib::StringList(composer);
            int first;
            int second;
            string_disk_to_disk_num(disk_str.toCString(true), first, second);
            m_Mp4Tag->itemListMap()["disk"] = TagLib::MP4::Item(first, second);
            m_Mp4Tag->itemListMap()["cpil"] = TagLib::MP4::Item(is_compilation);
        }
        
        if(changedflag & CHANGED_DATA_RATING) {
            char* c_rating;
            if(asprintf (&c_rating, "%u", rating_to_popularity(rating)) >= 0) {
                m_Mp4Tag->itemListMap()["----:com.apple.iTunes:RATING" ] = TagLib::MP4::Item(c_rating);
                free(c_rating);
            }
            
            char* c_count;
            if(asprintf (&c_count, "%u", playcount) >= 0) {
                m_Mp4Tag->itemListMap()[ "----:com.apple.iTunes:PLAY_COUNTER" ] = TagLib::MP4::Item(c_count);
                free(c_count);
            }
        }
        
        if(changedflag & CHANGED_DATA_LABELS) {
            // The Labels
            mp4_check_label_frame(m_Mp4Tag, "----:com.apple.iTunes:ARTIST_LABELS", artist_labels_str);
            mp4_check_label_frame(m_Mp4Tag, "----:com.apple.iTunes:ALBUM_LABELS", album_labels_str);
            mp4_check_label_frame(m_Mp4Tag, "----:com.apple.iTunes:TRACK_LABELS", track_labels_str);
        }
    }
    return Info::write(changedflag);
}

//#ifdef TAGLIB_WITH_MP4_COVERS
bool Mp4Info::can_handle_images(void) {
    return true;
}

bool Mp4Info::get_image(char*& data, int &data_length) const {
    if(m_Mp4Tag) {
        String mime = get_mp4_cover_art(m_Mp4Tag, data, data_length);
        if(! data || data_length <= 0)
            return false;
        return true;
    }
    return false;
}

bool Mp4Info::set_image(char* data, int data_length) {
    return false;
}

//
//bool Mp4Info::can_handle_images(void)
//{
//    return true;
//}

//
//wxImage * Mp4Info::get_image(void)
//{
//    return get_mp4_cover_art(m_Mp4Tag);
//}

//
//bool Mp4Info::set_image(const wxImage * image)
//{
//    return set_mp4_cover_art(m_Mp4Tag, image);
//}
//#endif


bool Mp4Info::can_handle_lyrics(void) {
    return true;
}


String Mp4Info::get_lyrics(void) {
    //TagLib::MP4::File tagfile(file_name.mb_str(wxConvFile));
    return get_mp4_lyrics(((TagLib::MP4::File *) taglib_file->file())->tag());
}


bool Mp4Info::set_lyrics(const String &lyrics) {
    return set_mp4_lyrics(((TagLib::MP4::File *) taglib_file->file())->tag(), lyrics);
}




