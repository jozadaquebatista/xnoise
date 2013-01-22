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
#include <xiphcomment.h>


static const string base64_chars = 
             "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
             "abcdefghijklmnopqrstuvwxyz"
             "0123456789+/";


static inline bool is_base64(unsigned char c) {
  return (isalnum(c) || (c == '+') || (c == '/'));
}


inline string base64_decode(const char* encoded_string) {
    int in_len = strlen(encoded_string);// encoded_string.size();
    int i = 0;
    int j = 0;
    int in_ = 0;
    unsigned char char_array_4[4], char_array_3[3];
    string ret;
    
    while(in_len-- && ( encoded_string[in_] != '=') && is_base64(encoded_string[in_])) {
        char_array_4[i++] = encoded_string[in_]; in_++;
        if (i ==4) {
        for (i = 0; i <4; i++)
            char_array_4[i] = base64_chars.find(char_array_4[i]);
        
        char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
        char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
        char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];
        
        for (i = 0; (i < 3); i++)
            ret += char_array_3[i];
            i = 0;
        }
    }
    
    if(i) {
        for (j = i; j <4; j++)
            char_array_4[j] = 0;
        
        for (j = 0; j <4; j++)
            char_array_4[j] = base64_chars.find(char_array_4[j]);
        
        char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
        char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
        char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];
        
        for (j = 0; (j < i - 1); j++)
            ret += char_array_3[j];
    }
    return ret;
}


String get_xiph_comment_lyrics(Ogg::XiphComment * xiphcomment) {
    if(xiphcomment && xiphcomment->contains("LYRICS")) {
        return xiphcomment->fieldListMap()[ "LYRICS" ].front();
    }
    return "";
}

bool set_xiph_comment_lyrics(Ogg::XiphComment * xiphcomment, const String &lyrics) {
    if(xiphcomment) {
        while(xiphcomment->contains("LYRICS")) {
            xiphcomment->removeField("LYRICS");
        }
        if(!lyrics.isEmpty()) {
            xiphcomment->addField("LYRICS", lyrics);
        }
        return true;
    }
    return false;
}



void check_xiph_label_frame(Ogg::XiphComment * xiphcomment, 
                                 const char * description, 
                                 const String &value) {
    if(xiphcomment->fieldListMap().contains(description)) {
            if(!value.isEmpty()) {
            xiphcomment->addField(description, value);
        }
        else {
            xiphcomment->removeField(description);
        }
    }
    else {
            if(!value.isEmpty()) {
            xiphcomment->addField(description, value);
        }
    }
}


String get_xiph_comment_cover_art(Ogg::XiphComment * xiphcomment, char*& data, int &data_length) {
    String CoverMime = "";
    if(xiphcomment && xiphcomment->contains("COVERART")) {
        CoverMime = xiphcomment->fieldListMap()[ "COVERARTMIME" ].front().to8Bit(false);
        
        const char* CoverEncData = xiphcomment->fieldListMap()[ "COVERART" ].front().toCString(true); // TODO: deprecated, use METADATA_BLOCK_PICTURE 
        
        //guLogMessage(wxT("Image:\n%s\n"), CoverEncData.c_str());
//        const string encoded_string = CoverEncData.data();
        
        string CoverDecData = base64_decode(CoverEncData);//.data());  //TODO needed?
        
        
//        wxMemoryBuffer CoverDecData = guBase64Decode(CoverEncData.data());
        
        //guLogMessage(wxT("Image Decoded Data : (%i) %i bytes"), CoverDecData.GetBufSize(), CoverDecData.GetDataLen());

        //wxFileOutputStream FOut(wxT("/home/jrios/test.jpg"));
        //FOut.write(CoverDecData.GetData(), CoverDecData.GetDataLen());
        //FOut.Close();

//        wxMemoryInputStream ImgInputStream(CoverDecData.GetData(), CoverDecData.GetDataLen());

        data_length = CoverDecData.size();
        data = new char[data_length];
        memcpy(data, CoverDecData.data(), CoverDecData.size());

//        data = strdup(CoverDecData.c_str());
//        data_length = CoverDecData.size();
//        wxImage * CoverImage = new wxImage(ImgInputStream, CoverMime);
//        if(CoverImage)
//        {
//            if(CoverImage->IsOk())
//            {
//                return CoverImage;
//            }
//            else
//            {
//                delete CoverImage;
//            }
//        }
    }
    return CoverMime;
}

//
//bool set_xiph_comment_cover_art(Ogg::XiphComment * xiphcomment, const wxImage * image)
//{
//    if(xiphcomment)
//    {
//        if(xiphcomment->contains("COVERART"))
//        {
//            xiphcomment->removeField("COVERARTMIME");
//            xiphcomment->removeField("COVERART");
//        }
//        if(image)
//        {
//            wxMemoryOutputStream ImgOutputStream;
//            if(image->SaveFile(ImgOutputStream, wxBITMAP_TYPE_JPEG))
//            {
//                //ByteVector ImgData((TagLib::uint) ImgOutputStream.GetSize());
//                //ImgOutputStream.CopyTo(ImgData.data(), ImgOutputStream.GetSize());
//                char * ImgData = (char *) malloc(ImgOutputStream.GetSize());
//                if(ImgData)
//                {
//                    ImgOutputStream.CopyTo(ImgData, ImgOutputStream.GetSize());
//                    xiphcomment->addField("COVERARTMIME", "image/jpeg");
//                    xiphcomment->addField("COVERART", guBase64Encode(ImgData, ImgOutputStream.GetSize()).data());
//                    free(ImgData);
//                    return true;
//                }
//                else
//                {
//                    guLogMessage(wxT("Couldnt allocate memory saving the image to ogg"));
//                }
//            }
//            return false;
//        }
//        return true;
//    }
//    return false;
//}

