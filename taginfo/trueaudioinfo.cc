#include "taginfo.h"
#include "taginfo_internal.h"



using namespace TagInfo;



TrueAudioInfo::TrueAudioInfo(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull()) {
            taglib_tagId3v2 = ((TagLib::TrueAudio::File *) taglib_file->file())->ID3v2Tag();
    }
    else {
            taglib_tagId3v2 = NULL;
    }
}


TrueAudioInfo::~TrueAudioInfo() {
}


bool TrueAudioInfo::read(void) {
    if(Info::read()) {
            // If its a ID3v2 Tag try to load the labels
        if(taglib_tagId3v2) {
            if(taglib_tagId3v2->frameListMap().contains("TPOS")) {
                disk_str = taglib_tagId3v2->frameListMap()[ "TPOS" ].front()->toString().toCString(true);
            }
            if(taglib_tagId3v2->frameListMap().contains("TCOM")) {
                composer = taglib_tagId3v2->frameListMap()[ "TCOM" ].front()->toString().toCString(true);
            }
            if(taglib_tagId3v2->frameListMap().contains("TPE2")) {
                album_artist = taglib_tagId3v2->frameListMap()[ "TPE2" ].front()->toString().toCString(true);
            }
            if(taglib_tagId3v2->frameListMap().contains("TCMP")) {
                is_compilation = taglib_tagId3v2->frameListMap()[ "TCMP" ].front()->toString().toCString(true) == (char*)"1";
            }
            TagLib::ID3v2::PopularimeterFrame * PopMFrame = NULL;

            PopMFrame = get_popularity_frame(taglib_tagId3v2, "LibTagInfo");
            if(!PopMFrame)
                PopMFrame = get_popularity_frame(taglib_tagId3v2, "");

            if(PopMFrame) {
                rating = popularity_to_rating(PopMFrame->rating());
                playcount = PopMFrame->counter();
            }


            if(track_labels.size() == 0) {
                ID3v2::UserTextIdentificationFrame * Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "TRACK_LABELS");
                if(!Frame)
                    Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "guTRLABELS");
                if(Frame)
                {
                    //guLogMessage(wxT("*Track Label: '%s'"), TStringTowxString(Frame->fieldList()[ 1 ]).c_str());
                    // [guTRLABELS] guTRLABELS labels
                    track_labels_str = Frame->fieldList()[ 1 ].toCString(true);
                    split(track_labels_str, "|" , track_labels);
//                    track_labels = Regex::split_simple("|", track_labels_str);//(track_labels_str, wxT("|"));
                }
            }
            if(artist_labels.size() == 0) {
                ID3v2::UserTextIdentificationFrame * Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "ARTIST_LABELS");
                if(!Frame)
                    Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "guARLABELS");
                if(Frame)
                {
                    //guLogMessage(wxT("*Artist Label: '%s'"), TStringTowxString(Frame->fieldList()[ 1 ]).c_str());
                    artist_labels_str = Frame->fieldList()[ 1 ].toCString(true);
                    split(artist_labels_str, "|" , artist_labels);
//                    artist_labels = Regex::split_simple("|", artist_labels_str);//(artist_labels_str, wxT("|"));
                }
            }
            if(album_labels.size() == 0) {
                ID3v2::UserTextIdentificationFrame * Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "ALBUM_LABELS");
                if(!Frame)
                    Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "guALLABELS");
                if(Frame)
                {
                    //guLogMessage(wxT("*Album Label: '%s'"), TStringTowxString(Frame->fieldList()[ 1 ]).c_str());
                    album_labels_str = Frame->fieldList()[ 1 ].toCString(true);
                    split(album_labels_str, "|" , album_labels);
//                    album_labels = Regex::split_simple("|", album_labels_str);//(album_labels_str, wxT("|"));
                }
            }
        }
    }
    else {
          printf("Error: Could not read tags from file '%s'\n", file_name.c_str());
      return false; //JM
    }
    return true;
}


bool TrueAudioInfo::write(const int changedflag) {
    if(taglib_tagId3v2) {
            if(changedflag & CHANGED_DATA_TAGS) {
            TagLib::ID3v2::TextIdentificationFrame * frame;
            taglib_tagId3v2->removeFrames("TPOS");
            frame = new TagLib::ID3v2::TextIdentificationFrame("TPOS");
            frame->setText(disk_str.c_str());
            taglib_tagId3v2->addFrame(frame);

            taglib_tagId3v2->removeFrames("TCOM");
            frame = new TagLib::ID3v2::TextIdentificationFrame("TCOM");
            frame->setText(composer.c_str());
            taglib_tagId3v2->addFrame(frame);

            taglib_tagId3v2->removeFrames("TPE2");
            frame = new TagLib::ID3v2::TextIdentificationFrame("TPE2");
            frame->setText(album_artist.c_str());
            taglib_tagId3v2->addFrame(frame);

            //taglib_tagId3v2->removeFrames("TCMP");
            //frame = new TagLib::ID3v2::TextIdentificationFrame("TCMP");
            //frame->setText(wxString::Format(wxT("%u"), is_compilation).c_str());
            //taglib_tagId3v2->addFrame(frame);

            // I have found several TRCK fields in the mp3s
            taglib_tagId3v2->removeFrames("TRCK");
            taglib_tagId3v2->setTrack(tracknumber);
        }

        if(changedflag & CHANGED_DATA_RATING) {
            printf("Writing ratings and playcount...\n");
            TagLib::ID3v2::PopularimeterFrame * PopMFrame = get_popularity_frame(taglib_tagId3v2, "LibTagInfo");
            if(!PopMFrame) {
                PopMFrame = new TagLib::ID3v2::PopularimeterFrame();
                taglib_tagId3v2->addFrame(PopMFrame);
                PopMFrame->setEmail("LibTagInfo");
            }
            PopMFrame->setRating(rating_to_popularity(rating));
            PopMFrame->setCounter(playcount);
        }
        
        if(changedflag & CHANGED_DATA_LABELS) {
            // The Labels
            id3v2_check_label_frame(taglib_tagId3v2, "ARTIST_LABELS", artist_labels_str);
            id3v2_check_label_frame(taglib_tagId3v2, "ALBUM_LABELS", album_labels_str);
            id3v2_check_label_frame(taglib_tagId3v2, "TRACK_LABELS", track_labels_str);
        }
    }
    return Info::write(changedflag);
}


bool TrueAudioInfo::can_handle_images(void) {
    return true;
}

bool TrueAudioInfo::get_image(char*& data, int &data_length) const {
    if(taglib_tagId3v2) {
            return get_id3v2_image(taglib_tagId3v2, data, data_length);
    }
    return false;
}

bool TrueAudioInfo::set_image(char* data, int data_length) {
    return false;
}

//bool TrueAudioInfo::can_handle_images(void)
//{
//    return true;
//}

//
//wxImage * TrueAudioInfo::get_image(void)
//{
//    if(taglib_tagId3v2)
//    {
//        return get_id3v2_image(taglib_tagId3v2);
//    }
//    return NULL;
//}

//
//bool TrueAudioInfo::set_image(const wxImage * image)
//{
//    if(taglib_tagId3v2)
//    {
//        SetID3v2Image(taglib_tagId3v2, image);
//    }
//    else
//        return false;

//    return true;
//}


bool TrueAudioInfo::can_handle_lyrics(void) {
    return true;
}


string TrueAudioInfo::get_lyrics(void) {
    if(taglib_tagId3v2) {
            return get_id3v2_lyrics(taglib_tagId3v2);
    }
    return "";
}


bool TrueAudioInfo::set_lyrics(const string &lyrics) {
    if(taglib_tagId3v2) {
            set_id3v2_lyrics(taglib_tagId3v2, lyrics);
        return true;
    }
    return false;
}







