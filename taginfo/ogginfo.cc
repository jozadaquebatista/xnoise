#include "taginfo.h"
#include "taginfo_internal.h"



using namespace TagInfo;



// OggInfo

OggInfo::OggInfo(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull()) {
            m_XiphComment = ((TagLib::Ogg::Vorbis::File *) taglib_file->file())->tag();
    }
    else
        m_XiphComment = NULL;
}


OggInfo::~OggInfo() {
}


bool OggInfo::read(void) {
    if(Info::read()) {
            if(m_XiphComment) {
            if(m_XiphComment->fieldListMap().contains("COMPOSER")) {
                composer = m_XiphComment->fieldListMap()["COMPOSER"].front().toCString(true);
            }
            if(m_XiphComment->fieldListMap().contains("DISCNUMBER")) {
                disk_str = m_XiphComment->fieldListMap()["DISCNUMBER"].front().toCString(true);
            }
            if(m_XiphComment->fieldListMap().contains("COMPILATION")) {
                is_compilation = m_XiphComment->fieldListMap()["COMPILATION"].front().toCString(true) == (char*)"1";
            }
            if(m_XiphComment->fieldListMap().contains("ALBUMARTIST")) {
                album_artist = m_XiphComment->fieldListMap()["ALBUMARTIST"].front().toCString(true);
            }
            else if(m_XiphComment->fieldListMap().contains("ALBUM ARTIST")) {
                album_artist = m_XiphComment->fieldListMap()["ALBUM ARTIST"].front().toCString(true);
            }
            // Rating
            if(m_XiphComment->fieldListMap().contains("RATING")) {
                long Rating = 0;
                Rating = atol(m_XiphComment->fieldListMap()["RATING"].front().toCString(true));
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
//                }
            }
            if(m_XiphComment->fieldListMap().contains("PLAY_COUNTER")) {
                long PlayCount = 0;
                PlayCount = atol(m_XiphComment->fieldListMap()["PLAY_COUNTER"].front().toCString(true));
//                {
                playcount = PlayCount;
//                }
            }
            // Labels
            if(track_labels.size() == 0) {
                if(m_XiphComment->fieldListMap().contains("TRACK_LABELS"))
                {
                    track_labels_str = m_XiphComment->fieldListMap()["TRACK_LABELS"].front().toCString(true);
                    //guLogMessage(wxT("*Track Label: '%s'\n"), track_labels_str.c_str());
                    split(track_labels_str, "|" , track_labels);
                }
            }
            if(artist_labels.size() == 0) {
                if(m_XiphComment->fieldListMap().contains("ARTIST_LABELS"))
                {
                    artist_labels_str = m_XiphComment->fieldListMap()["ARTIST_LABELS"].front().toCString(true);
                    //guLogMessage(wxT("*Artist Label: '%s'\n"), artist_labels_str.c_str());
                    split(artist_labels_str, "|" , artist_labels);
                }
            }
            if(album_labels.size() == 0) {
                if(m_XiphComment->fieldListMap().contains("ALBUM_LABELS"))
                {
                    album_labels_str = m_XiphComment->fieldListMap()["ALBUM_LABELS"].front().toCString(true);
                    //guLogMessage(wxT("*Album Label: '%s'\n"), album_labels_str.c_str());
                    split(album_labels_str, "|" , album_labels);
                }
            }
            return true;
        }
    }
    return false;
}


bool OggInfo::write(const int changedflag) {
    if(m_XiphComment) {
            if(changedflag & CHANGED_DATA_TAGS) {
            m_XiphComment->addField("DISCNUMBER", disk_str.c_str());
            m_XiphComment->addField("COMPOSER", composer.c_str());
            
            char* str;
            if(asprintf (&str, "%u" , is_compilation) >= 0) {
                m_XiphComment->addField("COMPILATION", str);
                free(str);
            }
            
            m_XiphComment->addField("ALBUMARTIST", album_artist.c_str());
        }

        if(changedflag & CHANGED_DATA_RATING) {
            char* str;
            if(asprintf (&str, "%u", rating_to_popularity(rating)) >= 0) {
                m_XiphComment->addField("RATING", str);
                free(str);
            }
            
            if(asprintf (&str, "%u", playcount) >= 0) {
                m_XiphComment->addField("PLAY_COUNTER", str);
                free(str);
            }
        }

        if(changedflag & CHANGED_DATA_LABELS) {
            // The Labels
            check_xiph_label_frame(m_XiphComment, "ARTIST_LABELS", artist_labels_str);
            check_xiph_label_frame(m_XiphComment, "ALBUM_LABELS", album_labels_str);
            check_xiph_label_frame(m_XiphComment, "TRACK_LABELS", track_labels_str);
        }
    }
    return Info::write(changedflag);
}

bool OggInfo::can_handle_images(void) {
    return true;
}

bool OggInfo::get_image(char*& data, int &data_length) const {
    data = NULL;
    data_length = 0;
    
    get_xiph_comment_cover_art(m_XiphComment, data, data_length);
    
    if(! (data) || (data_length <= 0)) {
            return false;
    }
    return true;
}

bool OggInfo::set_image(char* data, int data_length) {
    return false;
}

//bool OggInfo::can_handle_images(void)
//{
//    return true;
//}

//
//wxImage * OggInfo::get_image(void)
//{
//    return get_xiph_comment_cover_art(m_XiphComment);
//}

//
//bool OggInfo::set_image(const wxImage * image)
//{
//    return set_xiph_comment_cover_art(m_XiphComment, image);
//}


bool OggInfo::can_handle_lyrics(void) {
    return true;
}


string OggInfo::get_lyrics(void) {
    return get_xiph_comment_lyrics(m_XiphComment);
}


bool OggInfo::set_lyrics(const string &lyrics) {
    return set_xiph_comment_lyrics(m_XiphComment, lyrics);
}




