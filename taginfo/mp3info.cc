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


#include <asfattribute.h>
#include <popularimeterframe.h>

using namespace TagInfo;





Mp3Info::Mp3Info(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull()) {
        taglib_tagId3v2 = ((TagLib::MPEG::File *) taglib_file->file())->ID3v2Tag();
    }
    else {
        taglib_tagId3v2 = NULL;
    }
}


Mp3Info::~Mp3Info() {

}


bool Mp3Info::read(void) {
    if(Info::read()) {
            // If its a ID3v2 Tag try to load the labels
        if(taglib_tagId3v2) {
            if(taglib_tagId3v2->frameListMap().contains("TPOS")) {
                disk_str = taglib_tagId3v2->frameListMap()[ "TPOS" ].front()->toString();
            }
            if(taglib_tagId3v2->frameListMap().contains("TCOM")) {
                composer = taglib_tagId3v2->frameListMap()[ "TCOM" ].front()->toString();
            }
            if(taglib_tagId3v2->frameListMap().contains("TPE2")) {
                album_artist = taglib_tagId3v2->frameListMap()[ "TPE2" ].front()->toString();
            }
            if(taglib_tagId3v2->frameListMap().contains("TCMP")) {
                is_compilation = (taglib_tagId3v2->frameListMap()["TCMP"].front()->toString()) == String("1");
            }
            TagLib::ID3v2::PopularimeterFrame * PopMFrame = NULL;

            PopMFrame = get_popularity_frame(taglib_tagId3v2, "LibTagInfo");
            if(!PopMFrame)
                PopMFrame = get_popularity_frame(taglib_tagId3v2, "");
            
            if(PopMFrame) {
                rating    = popularity_to_rating(PopMFrame->rating());
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
                    StringList TrLabelsList = Frame->fieldList();
                    if(TrLabelsList.size())
                    {
                        track_labels_str = TrLabelsList[ 1 ];
                        track_labels = split(track_labels_str, "|");
                    }
                }
            }
            if(artist_labels.size() == 0) {
                ID3v2::UserTextIdentificationFrame * Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "ARTIST_LABELS");
                if(!Frame)
                    Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "guARLABELS");
                if(Frame)
                {
                    //guLogMessage(wxT("*Artist Label: '%s'"), TStringTowxString(Frame->fieldList()[ 1 ]).c_str());
                    StringList ArLabelsList = Frame->fieldList();
                    if(ArLabelsList.size())
                    {
                        artist_labels_str = ArLabelsList[ 1 ];//.toCString(true);
                        artist_labels = split(artist_labels_str, "|");
                    }
                }
            }
            if(album_labels.size() == 0) {
                ID3v2::UserTextIdentificationFrame * Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "ALBUM_LABELS");
                if(!Frame)
                    Frame = ID3v2::UserTextIdentificationFrame::find(taglib_tagId3v2, "guALLABELS");
                if(Frame)
                {
                    //guLogMessage(wxT("*Album Label: '%s'"), TStringTowxString(Frame->fieldList()[ 1 ]).c_str());
                    StringList AlLabelsList = Frame->fieldList();
                    if(AlLabelsList.size())
                    {
                        album_labels_str = AlLabelsList[1];//.toCString(true);
                        album_labels = split(album_labels_str, "|");
                    }
                }
            }
        }
        
    }
    else {
          cout  << "Error: Could not read tags from file '" << file_name.toCString(true) << "'" <<  endl;//printf("Error: Could not read tags from file '%s'\n", file_name.data());
        return false; //JM
    }
    return true;
}




bool Mp3Info::write(const int changedflag) {
    if(taglib_tagId3v2) {
        if(changedflag & CHANGED_DATA_TAGS) {
            TagLib::ID3v2::TextIdentificationFrame * frame;
            taglib_tagId3v2->removeFrames("TPOS");
            frame = new TagLib::ID3v2::TextIdentificationFrame("TPOS");
            frame->setText(disk_str);
            taglib_tagId3v2->addFrame(frame);
            
            taglib_tagId3v2->removeFrames("TCOM");
            frame = new TagLib::ID3v2::TextIdentificationFrame("TCOM");
            frame->setText(composer);
            taglib_tagId3v2->addFrame(frame);
            
            taglib_tagId3v2->removeFrames("TPE2");
            frame = new TagLib::ID3v2::TextIdentificationFrame("TPE2");
            frame->setText(album_artist);
            taglib_tagId3v2->addFrame(frame);
            
            taglib_tagId3v2->removeFrames("TCMP"); //JM **********
            frame = new TagLib::ID3v2::TextIdentificationFrame("TCMP");
            if(is_compilation)
                frame->setText("1");
            else
                frame->setText("0");
            taglib_tagId3v2->addFrame(frame);
            
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


bool Mp3Info::can_handle_images(void) {
    return true;
}

bool Mp3Info::get_image(char*& data, int &data_length) const {
    data = NULL;
    data_length = 0;
    
    if(taglib_tagId3v2) {
        return get_id3v2_image(taglib_tagId3v2, data, data_length);
    }
    return false;
}

bool Mp3Info::set_image(char* data, int data_length) {
    return false;
}


//bool Mp3Info::can_handle_images(void)
//{
//    return true;
//}

//
//wxImage * Mp3Info::get_image(void)
//{
//    if(taglib_tagId3v2)
//    {
//        return get_id3v2_image(taglib_tagId3v2);
//    }
//    return NULL;
//}

//
//bool Mp3Info::set_image(const wxImage * image)
//{
//    if(taglib_tagId3v2)
//    {
//        SetID3v2Image(taglib_tagId3v2, image);
//    }
//    else
//        return false;

//    return true;
//}


bool Mp3Info::can_handle_lyrics(void) {
    return true;
}


String Mp3Info::get_lyrics(void) {
    if(taglib_tagId3v2) {
            return get_id3v2_lyrics(taglib_tagId3v2);
    }
    return "";
}


bool Mp3Info::set_lyrics(const String &lyrics) {
    if(taglib_tagId3v2) {
            set_id3v2_lyrics(taglib_tagId3v2, lyrics);
        return true;
    }
    return false;
}






