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

#include <string>
#include "taginfo.h"
#include "taginfo_internal.h"


void check_ape_label_frame(TagLib::APE::Tag * apetag, const char * description, const String &value) {
    if(apetag->itemListMap().contains(description))
        apetag->removeItem(description);
    if(!value.isEmpty()) {
            apetag->addValue(description, value);//.c_str());
    }
}


String get_ape_item_image(const TagLib::APE::Item &item, char*& data, int &data_length) {
    String mime = "";
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


String get_ape_image(TagLib::APE::Tag * apetag, char*& data, int &data_length) {
    data = NULL;
    data_length = 0;
    String mime = "";
    
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



String get_ape_lyrics(APE::Tag * apetag) {
    if(apetag) {
            if(apetag->itemListMap().contains("LYRICS")) {
            return apetag->itemListMap()[ "LYRICS" ].toStringList().front();
        }
        else if(apetag->itemListMap().contains("UNSYNCED LYRICS")) {
            return apetag->itemListMap()[ "UNSYNCED LYRICS" ].toStringList().front();
        }
    }
    return "";
}


bool set_ape_lyrics(APE::Tag * apetag, const String &lyrics) {
    if(apetag) {
            if(apetag->itemListMap().contains("LYRICS")) {
            apetag->removeItem("LYRICS");
        }
        if(apetag->itemListMap().contains("UNSYNCED LYRICS")) {
            apetag->removeItem("UNSYNCED LYRICS");
        }
        if(!lyrics.isEmpty()) {
//            const TagLib::String Lyrics = lyrics.data();
            apetag->addValue("Lyrics", lyrics);
        }
        return true;
    }
    return false;
}

