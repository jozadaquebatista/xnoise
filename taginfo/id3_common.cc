#include <string>
#include "taginfo.h"
#include "taginfo_internal.h"
#include <stdio.h>
#include <id3v2tag.h>


void id3v2_check_label_frame(ID3v2::Tag * tagv2, const string& description, const string &value) {
    ID3v2::UserTextIdentificationFrame * frame;
    //guLogMessage(wxT("USERTEXT[ '%s' ] = '%s'"), wxString(description, wxConvUTF8).c_str(), value.c_str());
    frame = ID3v2::UserTextIdentificationFrame::find(tagv2, description);
    if(!frame) {
        frame = new ID3v2::UserTextIdentificationFrame(TagLib::String::UTF8);
        tagv2->addFrame(frame);
        frame->setDescription(TagLib::String(description.c_str(), TagLib::String::UTF8));
    }
    if(frame) {
            frame->setText(value.data());
    }
}

string get_id3v2_lyrics(ID3v2::Tag * tagv2) {
    TagLib::ID3v2::FrameList frameList = tagv2->frameList("USLT");
    if(!frameList.isEmpty()) {
        TagLib::ID3v2::UnsynchronizedLyricsFrame * LyricsFrame = 
            static_cast<TagLib::ID3v2::UnsynchronizedLyricsFrame * >(frameList.front());
        if(LyricsFrame) {
            //guLogMessage(wxT("Found lyrics"));
            return string(LyricsFrame->text().toCString(true));
        }
    }
    return string("");
}

string get_typed_id3v2_image(char*& idata, int &idata_length,
                         TagLib::ID3v2::FrameList &framelist,
                         TagLib::ID3v2::AttachedPictureFrame::Type frametype) {
    TagLib::ID3v2::AttachedPictureFrame * PicFrame;
    string mimetype = "";
    idata = NULL;
    idata_length = 0;
    
    for(list<TagLib::ID3v2::Frame*>::iterator iter = framelist.begin(); iter != framelist.end(); iter++) {
        PicFrame = static_cast<TagLib::ID3v2::AttachedPictureFrame *>(*iter);
        
        if(PicFrame->type() == frametype) {
            if(PicFrame->picture().size() > 0) {
                idata_length = PicFrame->picture().size();
                idata = new char[idata_length];
                memcpy(idata, PicFrame->picture().data(), PicFrame->picture().size());
                //FILE * fout;
                //fout = fopen("outputFile.jpg", "wb");
                //cout<<"processing the file " <<endl <<endl;
                //fwrite(idata, idata_length, 1, fout);
                //fclose(fout);
                //cout<<"The picture has been written" << endl;
                mimetype = PicFrame->mimeType().toCString(true);
                find_and_replace(mimetype, "/jpg", "/jpeg");
            }
        }
    }
    return mimetype;
}


TagLib::ID3v2::PopularimeterFrame * get_popularity_frame(TagLib::ID3v2::Tag * tag, const TagLib::String &email) {
    TagLib::ID3v2::FrameList PopMList = tag->frameList("POPM");
    for(TagLib::ID3v2::FrameList::Iterator it = PopMList.begin(); it != PopMList.end(); ++it) {
            TagLib::ID3v2::PopularimeterFrame * PopMFrame = static_cast<TagLib::ID3v2::PopularimeterFrame *>(* it);
        //printf("PopM e: '%s'  r: %i  c: %i", TStringTowxString(PopMFrame->email()).c_str(), PopMFrame->rating(), PopMFrame->counter());
        if(email.isEmpty() || (PopMFrame->email() == email)) {
            return PopMFrame;
        }
    }
    return NULL;
}



bool get_id3v2_image(ID3v2::Tag * tagv2, char*& data, int &data_length) {
    TagLib::ID3v2::FrameList FrameList = tagv2->frameListMap()["APIC"];
    //cout << "get front cover" << endl;
    string mime = get_typed_id3v2_image(data, data_length,
                                     FrameList, 
                                     TagLib::ID3v2::AttachedPictureFrame::FrontCover);
    
    if(! (data) || (data_length <= 0)) {
        //cout << "try get attached image" << endl;
        get_typed_id3v2_image(data, data_length, FrameList, TagLib::ID3v2::AttachedPictureFrame::Other);
    }
    if(! (data) || (data_length <= 0)) {
        //cout << "not getting image" << endl;
        return false;
    }
    return true;
}


void set_id3v2_lyrics(ID3v2::Tag * tagv2, const string &lyrics) {
    //guLogMessage(wxT("Saving lyrics..."));
    TagLib::ID3v2::UnsynchronizedLyricsFrame * LyricsFrame;
    
    TagLib::ID3v2::FrameList FrameList = tagv2->frameListMap()["USLT"];
    for(list<TagLib::ID3v2::Frame*>::iterator iter = FrameList.begin(); iter != FrameList.end(); iter++) {
            LyricsFrame = static_cast<TagLib::ID3v2::UnsynchronizedLyricsFrame*>(*iter);
        tagv2->removeFrame(LyricsFrame, true);
    }
    if(!lyrics.empty()) {
        LyricsFrame = new TagLib::ID3v2::UnsynchronizedLyricsFrame(TagLib::String::UTF8);
        LyricsFrame->setText(lyrics.data());
        tagv2->addFrame(LyricsFrame);
    }
}


