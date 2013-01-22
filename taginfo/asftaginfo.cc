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
#include "tstring.h"
#include "tag.h"
#include "taglib.h"
#include "tbytevector.h"


using namespace TagInfo;



String get_asf_image(ASF::Tag * asftag, char*& data, int &data_length) {
    data = NULL;
    data_length = 0;
    String mime = "";
    
    if(asftag) {
            if(asftag->attributeListMap().contains("WM/Picture")) {
            ByteVector PictureData = asftag->attributeListMap()[ "WM/Picture" ].front().toByteVector();
            
            TagLib::ID3v2::AttachedPictureFrame * PicFrame;
            
            PicFrame = (TagLib::ID3v2::AttachedPictureFrame *) PictureData.data();
            
            if(PicFrame->picture().size() > 0) {
                data_length = PicFrame->picture().size();
                data = new char[data_length];
                memcpy(data, PicFrame->picture().data(), PicFrame->picture().size());
                mime = PicFrame->mimeType().toCString(true);
//                find_and_replace(mime, "/jpg", "/jpeg"); //TODO
            }
        }
    }
    return mime;
}

//
//bool set_asf_image(ASF::Tag * asftag, const wxImage * image)
//{
//    return NULL;
//}


ASFTagInfo::ASFTagInfo(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull()) {
            m_ASFTag = ((TagLib::ASF::File *) taglib_file->file())->tag();
    }
    else {
            m_ASFTag = NULL;
    }
}


ASFTagInfo::~ASFTagInfo() {

}


bool ASFTagInfo::read(void) {
    if(Info::read()) {
        if(m_ASFTag) {
            if(m_ASFTag->attributeListMap().contains("WM/PartOfSet")) {
                disk_str = m_ASFTag->attributeListMap()[ "WM/PartOfSet" ].front().toString();
            }
            if(m_ASFTag->attributeListMap().contains("WM/Composer")) {
                composer = m_ASFTag->attributeListMap()[ "WM/Composer" ].front().toString();
            }
            if(m_ASFTag->attributeListMap().contains("WM/AlbumArtist")) {
                album_artist = m_ASFTag->attributeListMap()[ "WM/AlbumArtist" ].front().toString();
            }
            long Rating = 0;
            if(m_ASFTag->attributeListMap().contains("WM/SharedUserRating")) {
                Rating = atol(m_ASFTag->attributeListMap()[ "WM/SharedUserRating" ].front().toString().toCString(false));
            }
            if(!Rating && m_ASFTag->attributeListMap().contains("Rating")) {
                Rating = atol(m_ASFTag->attributeListMap()[ "Rating" ].front().toString().toCString(false));
            }
            if(Rating) {
                if(Rating > 5)
                {
                    rating = wm_rating_to_rating(Rating);
                }
                else
                {
                    rating = Rating;
                }
            }


            if(track_labels.size() == 0) {
                if(m_ASFTag->attributeListMap().contains("TRACK_LABELS")){
//                    track_labels_str = m_ASFTag->attributeListMap()[ "TRACK_LABELS" ].front().toString();
                    track_labels_str = m_ASFTag->attributeListMap()[ "TRACK_LABELS" ].front().toString();
//                    track_labels = track_labels_str.split("|");
//                    track_labels = Regex::split_simple("|", track_labels_str);//(track_labels_str, wxT("|"));
                }
            }
            if(artist_labels.size() == 0) {
                if(m_ASFTag->attributeListMap().contains("ARTIST_LABELS"))
                {
                    artist_labels_str = m_ASFTag->attributeListMap()[ "ARTIST_LABELS" ].front().toString();
//                    artist_labels = artist_labels_str.split("|");
//                    artist_labels = Regex::split_simple("|", artist_labels_str);//(artist_labels_str, wxT("|"));
                }
            }
            if(album_labels.size() == 0) {
                if(m_ASFTag->attributeListMap().contains("ALBUM_LABELS"))
                {
                    album_labels_str = m_ASFTag->attributeListMap()[ "ALBUM_LABELS" ].front().toString();
//                    album_labels = album_labels_str.split("|");
//                    album_labels = Regex::split_simple("|", album_labels_str);//(album_labels_str, wxT("|"));
                }
            }
        }
    }
    else {
        printf("Error: Could not read tags from file '%s'\n", file_name.toCString(true));
        return false; //JM
    }
    return true;
}


void check_asf_label_frame(ASF::Tag * asftag, const char * description, const String &value) {
    //guLogMessage(wxT("USERTEXT[ %s ] = '%s'"), wxString(description, wxConvISO8859_1).c_str(), value.c_str());
    if(asftag->attributeListMap().contains(description))
        asftag->removeItem(description);
    if(!value.isEmpty()) {
            asftag->setAttribute(description, value);
    }
}


bool ASFTagInfo::write(const int changedflag) {
    if(m_ASFTag) {
        if(changedflag & CHANGED_DATA_TAGS) {
            m_ASFTag->removeItem("WM/PartOfSet");
            m_ASFTag->setAttribute("WM/PartOfSet", disk_str);
            
            m_ASFTag->removeItem("WM/Composer");
            m_ASFTag->setAttribute("WM/Composer", composer);
            
            m_ASFTag->removeItem("WM/AlbumArtist");
            m_ASFTag->setAttribute("WM/AlbumArtist", album_artist);
        }
        
        if(changedflag & CHANGED_DATA_RATING) {
            m_ASFTag->removeItem("WM/SharedUserRating");
            int WMRatings[] = { 0, 0, 1, 25, 50, 75, 99 };
            
            char* str;
            if(asprintf (&str, "%i", WMRatings[ rating + 1 ]) >= 0) {
                m_ASFTag->setAttribute("WM/SharedUserRating", str);
                free(str);
            }
        }
        
        if(changedflag & CHANGED_DATA_LABELS) {
            // The Labels
            check_asf_label_frame(m_ASFTag, "ARTIST_LABELS", artist_labels_str);
            check_asf_label_frame(m_ASFTag, "ALBUM_LABELS", album_labels_str);
            check_asf_label_frame(m_ASFTag, "TRACK_LABELS", track_labels_str);
        }
    }
    return Info::write(changedflag);
}


bool ASFTagInfo::can_handle_images(void) {
    return true; // TODO can save images ?
}

bool ASFTagInfo::get_image(char*& data, int &data_length) const {
    if(m_ASFTag) {
            String mime;
        mime = get_asf_image(m_ASFTag, data, data_length);
        
        if(! data || data_length <= 0);
            return false;
        
        return true;
    }
    return false;
}

bool ASFTagInfo::set_image(char* data, int data_length) {
    return false;
}

//bool ASFTagInfo::can_handle_images(void)
//{
//    return false;
//}

//
//wxImage * ASFTagInfo::get_image(void)
//{
//    if(m_ASFTag)
//    {
//        return get_asf_image(m_ASFTag);
//    }
//    return NULL;
//}

//
//bool ASFTagInfo::set_image(const wxImage * image)
//{
//    if(m_ASFTag)
//    {
//        set_asf_image(m_ASFTag, image);
//    }
//    else
//        return false;

//    return true;
//}


bool ASFTagInfo::can_handle_lyrics(void) {
    return true;
}


String ASFTagInfo::get_lyrics(void) {
    if(m_ASFTag) {
            if(m_ASFTag->attributeListMap().contains("WM/Lyrics")) {
            return m_ASFTag->attributeListMap()[ "WM/Lyrics" ].front().toString();
        }
    }
    return "";
}


bool ASFTagInfo::set_lyrics(const String &lyrics) {
    if(m_ASFTag) {
            m_ASFTag->removeItem("WM/Lyrics");
        m_ASFTag->setAttribute("WM/Lyrics", lyrics);
        return true;
    }
    return false;
}




