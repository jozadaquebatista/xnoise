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



WavPackInfo::WavPackInfo(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull()) {
            taglib_apetag = ((TagLib::WavPack::File *) taglib_file->file())->APETag();
    }
    else
        taglib_apetag = NULL;
}


WavPackInfo::~WavPackInfo() {
}


bool WavPackInfo::read(void) {
    if(Info::read()) {
            if(taglib_apetag) {
            if(taglib_apetag->itemListMap().contains("COMPOSER")) {
                composer = taglib_apetag->itemListMap()["COMPOSER"].toStringList().front();
            }
            if(taglib_apetag->itemListMap().contains("DISCNUMBER")) {
                disk_str = taglib_apetag->itemListMap()["DISCNUMBER"].toStringList().front();
            }
            if(taglib_apetag->itemListMap().contains("COMPILATION")) {
                is_compilation = taglib_apetag->itemListMap()["COMPILATION"].toStringList().front() == String("1");
            }
            if(taglib_apetag->itemListMap().contains("ALBUM ARTIST")) {
                album_artist = taglib_apetag->itemListMap()["ALBUM ARTIST"].toStringList().front();
            }
            else if(taglib_apetag->itemListMap().contains("ALBUMARTIST")) {
                album_artist = taglib_apetag->itemListMap()["ALBUMARTIST"].toStringList().front();
            }
            // Rating
            if(taglib_apetag->itemListMap().contains("RATING")) {
                long Rating = 0;
                Rating = atol(taglib_apetag->itemListMap()["RATING"].toStringList().front().toCString(true));
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
            if(taglib_apetag->itemListMap().contains("PLAY_COUNTER")) {
                long PlayCount = 0;
                PlayCount = atol(taglib_apetag->itemListMap()["PLAY_COUNTER"].toStringList().front().toCString(true));
                playcount = PlayCount;
            }
            // Labels
            if(track_labels.size() == 0) {
                if(taglib_apetag->itemListMap().contains("TRACK_LABELS"))
                {
                    track_labels_str = taglib_apetag->itemListMap()["TRACK_LABELS"].toStringList().front();
                    track_labels = split(track_labels_str, "|");
                }
            }
            if(artist_labels.size() == 0) {
                if(taglib_apetag->itemListMap().contains("ARTIST_LABELS"))
                {
                    artist_labels_str = taglib_apetag->itemListMap()["ARTIST_LABELS"].toStringList().front();
                    artist_labels = split(artist_labels_str, "|");
                }
            }
            if(album_labels.size() == 0) {
                if(taglib_apetag->itemListMap().contains("ALBUM_LABELS"))
                {
                    album_labels_str = taglib_apetag->itemListMap()["ALBUM_LABELS"].toStringList().front();
                    album_labels = split(album_labels_str, "|");
                }
            }
            return true; //JM
        }
//        return true; // JM
    }
    return false;
}


bool WavPackInfo::write(const int changedflag) {
    if(taglib_apetag) {
            if(changedflag & CHANGED_DATA_TAGS) {
            taglib_apetag->addValue("COMPOSER", composer);
            taglib_apetag->addValue("DISCNUMBER", disk_str);
            
            char* str;
            if(is_compilation) {
                taglib_apetag->addValue("COMPILATION", "1");
            }
            else {
                taglib_apetag->addValue("COMPILATION", "0");
            }
            
            taglib_apetag->addValue("ALBUM ARTIST", album_artist);
        }
        
        if(changedflag & CHANGED_DATA_RATING) {
            char* str;
            
            if(asprintf (&str, "%u", rating_to_popularity(rating)) >= 0) {
                taglib_apetag->addValue("RATING", str);
                free(str);
                str = NULL;
            }
            
            if(asprintf (&str, "%u", playcount) >= 0) {
                taglib_apetag->addValue("PLAY_COUNTER", str);
                free(str);
            }
        }

        if(changedflag & CHANGED_DATA_LABELS) {
            // The Labels
            check_ape_label_frame(taglib_apetag, "ARTIST_LABELS", artist_labels_str);
            check_ape_label_frame(taglib_apetag, "ALBUM_LABELS", album_labels_str);
            check_ape_label_frame(taglib_apetag, "TRACK_LABELS", track_labels_str);
        }
    }
    return Info::write(changedflag);
}

bool WavPackInfo::can_handle_images(void) {
    return false;
}

bool WavPackInfo::get_image(char*& data, int &data_length, ImageType &image_type) {
    return get_ape_image(taglib_apetag, data, data_length, image_type);
}

bool WavPackInfo::set_image(char* data, int data_length, ImageType image_type) {
    return set_ape_image(taglib_apetag, data, data_length, image_type);
}
//
//bool WavPackInfo::can_handle_images(void)
//{
//    return true;
//}


//wxImage * WavPackInfo::get_image(void)
//{
//    return get_ape_image(taglib_apetag);
//}

//
//bool WavPackInfo::set_image(const wxImage * image)
//{
//    return taglib_apetag && set_ape_image(taglib_apetag, image);
//}


bool WavPackInfo::can_handle_lyrics(void) {
    return true;
}


String WavPackInfo::get_lyrics(void) {
    return get_ape_lyrics(taglib_apetag);
}


bool WavPackInfo::set_lyrics(const String &lyrics) {
    return set_ape_lyrics(taglib_apetag, lyrics);
}


