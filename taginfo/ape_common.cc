#include <string>
#include "taginfo.h"
#include "taginfo_internal.h"
//#include <apetag.h>


void check_ape_label_frame(TagLib::APE::Tag * apetag, const char * description, const string &value) {
    //guLogMessage(wxT("USERTEXT[ %s ] = '%s'"), wxString(description, wxConvISO8859_1).c_str(), value.c_str());
    if(apetag->itemListMap().contains(description))
        apetag->removeItem(description);
    if(!value.empty()) {
            apetag->addValue(description, value.c_str());
    }
}


string get_ape_item_image(const TagLib::APE::Item &item, char*& data, int &data_length) {
    string mime = "";
    if(item.type() == TagLib::APE::Item::Binary) {
        TagLib::ByteVector CoverData = item.value();
        if(CoverData.size()) {
            data_length = CoverData.size();
            data = new char[data_length];
            memcpy(data, CoverData.data(), CoverData.size());
            mime = "image/jpeg";
        }
    }
    return mime;
}



//
string get_ape_image(TagLib::APE::Tag * apetag, char*& data, int &data_length) {
    data = NULL;
    data_length = 0;
    string mime = "";
    
    if(apetag) {
        if(apetag->itemListMap().contains("Cover Art (front)")) {
            mime = get_ape_item_image(apetag->itemListMap()[ "Cover Art (front)" ],
                                    data, data_length);
        }
        else if(apetag->itemListMap().contains("Cover Art (other)")) {
            mime = get_ape_item_image(apetag->itemListMap()[ "Cover Art (other)" ],
                                    data, data_length);
        }
    }
    return mime;
}

//
//bool set_ape_image(TagLib::APE::Tag * apetag, const wxImage * image)
//{
//    return false;
//}



string get_ape_lyrics(APE::Tag * apetag) {
    if(apetag) {
            if(apetag->itemListMap().contains("LYRICS")) {
            return apetag->itemListMap()[ "LYRICS" ].toStringList().front().toCString(true);
        }
        else if(apetag->itemListMap().contains("UNSYNCED LYRICS")) {
            return apetag->itemListMap()[ "UNSYNCED LYRICS" ].toStringList().front().toCString(true);
        }
    }
    return "";
}


bool set_ape_lyrics(APE::Tag * apetag, const string &lyrics) {
    if(apetag) {
            if(apetag->itemListMap().contains("LYRICS")) {
            apetag->removeItem("LYRICS");
        }
        if(apetag->itemListMap().contains("UNSYNCED LYRICS")) {
            apetag->removeItem("UNSYNCED LYRICS");
        }
        if(!lyrics.empty()) {
            const TagLib::String Lyrics = lyrics.data();
            apetag->addValue("Lyrics", Lyrics);
        }
        return true;
    }
    return false;
}

