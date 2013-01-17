#include "taginfo.h"
#include "taginfo_internal.h"


using namespace TagInfo;



MpcInfo::MpcInfo(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull())
        taglib_apetag = ((TagLib::MPC::File *) taglib_file->file())->APETag();
    else
        taglib_apetag = NULL;
}


MpcInfo::~MpcInfo() {
}

bool MpcInfo::can_handle_images(void) {
    return true;
}

bool MpcInfo::get_image(char*& data, int &data_length) const {
    if(taglib_apetag) {
        string mime = get_ape_image(taglib_apetag, data, data_length);
        if(! data || data_length <= 0)
            return false;
        return true;
    }
    return false;
}

bool MpcInfo::set_image(char* data, int data_length) {
    return false;
}

//bool MpcInfo::can_handle_images(void)
//{
//    return true;
//}

//
//wxImage * MpcInfo::get_image(void)
//{
//    return get_ape_image(taglib_apetag);
//}

//
//bool MpcInfo::set_image(const wxImage * image)
//{
//    //return taglib_apetag && set_ape_image(taglib_apetag, image) && write();
//    return taglib_apetag && set_ape_image(taglib_apetag, image);
//}




bool MpcInfo::read(void) {
    if(Info::read()) {
        if(taglib_apetag) {
            if(taglib_apetag->itemListMap().contains("COMPOSER")) {
                composer = taglib_apetag->itemListMap()["COMPOSER"].toStringList().front().toCString(true);
            }
            if(taglib_apetag->itemListMap().contains("DISCNUMBER")) {
                disk_str = taglib_apetag->itemListMap()["DISCNUMBER"].toStringList().front().toCString(true);
            }
            if(taglib_apetag->itemListMap().contains("COMPILATION")) {
                is_compilation = taglib_apetag->itemListMap()["COMPILATION"].toStringList().front().toCString(true) ==  (char*)"1";
            }
            if(taglib_apetag->itemListMap().contains("ALBUM ARTIST")) {
                album_artist = taglib_apetag->itemListMap()["ALBUM ARTIST"].toStringList().front().toCString(true);
            }
            else if(taglib_apetag->itemListMap().contains("ALBUMARTIST")) {
                album_artist = taglib_apetag->itemListMap()["ALBUMARTIST"].toStringList().front().toCString(true);
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
                    track_labels_str = taglib_apetag->itemListMap()["TRACK_LABELS"].toStringList().front().toCString(true);
                    //guLogMessage(wxT("*Track Label: '%s'\n"), track_labels_str.c_str());
                    split(track_labels_str, "|" , track_labels);
//                    track_labels = Regex::split_simple("|", track_labels_str);//(track_labels_str, wxT("|"));
                }
            }
            if(artist_labels.size() == 0) {
                if(taglib_apetag->itemListMap().contains("ARTIST_LABELS"))
                {
                    artist_labels_str = taglib_apetag->itemListMap()["ARTIST_LABELS"].toStringList().front().toCString(true);
                    //guLogMessage(wxT("*Artist Label: '%s'\n"), artist_labels_str.c_str());
                    split(artist_labels_str, "|" , artist_labels);
//                    artist_labels = Regex::split_simple("|", artist_labels_str);//(artist_labels_str, wxT("|"));
                }
            }
            if(album_labels.size() == 0) {
                if(taglib_apetag->itemListMap().contains("ALBUM_LABELS"))
                {
                    album_labels_str = taglib_apetag->itemListMap()["ALBUM_LABELS"].toStringList().front().toCString(true);
                    //guLogMessage(wxT("*Album Label: '%s'\n"), album_labels_str.c_str());
                    split(album_labels_str, "|" , album_labels);
//                    album_labels = Regex::split_simple("|", album_labels_str);//(album_labels_str, wxT("|"));
                }
            }
            return true; //JM
        }
//        return true; //JM
    }
    return false;
}


bool MpcInfo::write(const int changedflag) {
    if(taglib_apetag) {
        if(changedflag & CHANGED_DATA_TAGS) {
            taglib_apetag->addValue("COMPOSER", composer.c_str());
            taglib_apetag->addValue("DISCNUMBER", disk_str.c_str());
            
            char* str;
            if(asprintf (&str, "%u", is_compilation) >= 0) {
                taglib_apetag->addValue("COMPILATION", str);
                free (str);
            }
            taglib_apetag->addValue("ALBUM ARTIST", album_artist.c_str());
        }
        if(changedflag & CHANGED_DATA_RATING) {
            char* str;
            
            if(asprintf (&str, "%u", rating_to_popularity(rating)) >= 0) {
                taglib_apetag->addValue("RATING", str);
                free (str);
                str = NULL;
            }
            
            if(asprintf (&str, "%u", playcount) >= 0) {
                taglib_apetag->addValue("PLAY_COUNTER", str);
                free (str);
            }
        }
        if(changedflag & CHANGED_DATA_LABELS) {
            // The Labels
            check_ape_label_frame(taglib_apetag, "ARTIST_LABELS", artist_labels_str);
            check_ape_label_frame(taglib_apetag, "ALBUM_LABELS",  album_labels_str);
            check_ape_label_frame(taglib_apetag, "TRACK_LABELS",  track_labels_str);
        }
    }
    return Info::write(changedflag);
}

//
//bool MpcInfo::can_handle_images(void)
//{
//    return true;
//}

//
//wxImage * MpcInfo::get_image(void)
//{
//    return get_ape_image();
//}

//
//bool MpcInfo::set_image(const wxImage * image)
//{
//    //return  && set_ape_image(, image) && write();
//    return  && set_ape_image(, image);
//}



