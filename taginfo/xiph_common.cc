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


static const string base64_char_string = 
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
    
    while(in_len-- && (encoded_string[in_] != '=') && is_base64(encoded_string[in_])) {
        char_array_4[i++] = encoded_string[in_]; in_++;
        if (i ==4) {
        for (i = 0; i <4; i++)
            char_array_4[i] = base64_char_string.find(char_array_4[i]);
        
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
            char_array_4[j] = base64_char_string.find(char_array_4[j]);
        
        char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
        char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
        char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];
        
        for (j = 0; (j < i - 1); j++)
            ret += char_array_3[j];
    }
    return ret;
}


static const char base64_chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char base64_pad = '=';

inline int base64encode_internal(const char * src, const size_t srclen, char * dst, const size_t dstlen) {
    if(((srclen / 3) + ((srclen % 3) > 0)) * 4 > dstlen)
        return -1;
    
    unsigned int tmp;
    const unsigned char * dat = ( unsigned char * ) src;
    int OutPos = 0;
    for(int i = 0; i < ( int ) srclen / 3; i++) {
        tmp  = (*dat++) << 16;
        tmp |= ((*dat++) <<  8);
        tmp |= (*dat++);
        dst[ OutPos++ ] = base64_chars[(tmp & 0x00FC0000 ) >> 18];
        dst[ OutPos++ ] = base64_chars[(tmp & 0x0003F000 ) >> 12];
        dst[ OutPos++ ] = base64_chars[(tmp & 0x00000FC0 ) >>  6];
        dst[ OutPos++ ] = base64_chars[(tmp & 0x0000003F )      ];
    }
    switch( srclen % 3 ) {
        case 1 :
            tmp = (* dat++) << 16;
            dst[OutPos++] = base64_chars[(tmp & 0x00FC0000 ) >> 18];
            dst[OutPos++] = base64_chars[(tmp & 0x0003F000 ) >> 12];
            dst[OutPos++] = base64_pad;
            dst[OutPos++] = base64_pad;
            break;
        case 2 :
            tmp  = (*dat++) << 16;
            tmp += (*dat++) <<  8;
            dst[OutPos++] = base64_chars[(tmp & 0x00FC0000 ) >> 18];
            dst[OutPos++] = base64_chars[(tmp & 0x0003F000 ) >> 12];
            dst[OutPos++] = base64_chars[(tmp & 0x00000FC0 ) >>  6];
            dst[OutPos++] = base64_pad;
            break;
    }
    return OutPos;
}

inline String base64encode(const char* src, const size_t srclen) {
    String RetVal;
    int dstlen = ((srclen / 3) + ((srclen % 3) > 0)) * 4;
    char * dst = (char *) malloc(dstlen);
    if(base64encode_internal(src, srclen, dst, dstlen) > 0) {
        ByteVector vect(dst, dstlen);
        RetVal = String(vect);
    }
    free(dst);
    return RetVal;
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


bool get_xiph_comment_cover_art(Ogg::XiphComment * xiphcomment, 
                                char*& data, int &data_length, 
                                ImageType &image_type) {
    if(xiphcomment && xiphcomment->contains("COVERART")) {
        String mimetype = xiphcomment->fieldListMap()[ "COVERARTMIME" ].front().to8Bit(false);
        if(mimetype.find("/jpeg") != -1 || mimetype.find("/jpg") != -1)
            image_type = IMAGE_TYPE_JPEG;
        else if(mimetype.find("/png") != -1)
            image_type = IMAGE_TYPE_PNG;
        
        // TODO: deprecated, use METADATA_BLOCK_PICTURE 
        const char* CoverEncData = xiphcomment->fieldListMap()[ "COVERART" ].front().toCString(true); 
        
        string CoverDecData = base64_decode(CoverEncData);
        
        data_length = CoverDecData.size();
        data = new char[data_length];
        memcpy(data, CoverDecData.data(), CoverDecData.size());
        
        return true;
    }
    return false;
}


bool set_xiph_comment_cover_art(Ogg::XiphComment * xiphcomment, 
                                char* data, int data_length, 
                                ImageType image_type) {
    if(xiphcomment) {
        if(xiphcomment->contains("COVERART")) {
            xiphcomment->removeField("COVERARTMIME");
            xiphcomment->removeField("COVERART");
        }
        if(data && data_length > 0) {
            if(image_type == IMAGE_TYPE_UNKNOWN || image_type == IMAGE_TYPE_JPEG)
                xiphcomment->addField("COVERARTMIME", "image/jpeg");
            else if(image_type == IMAGE_TYPE_PNG)
                xiphcomment->addField("COVERARTMIME", "image/png");
            xiphcomment->addField("COVERART", base64encode(data, data_length).toCString(false));
            return true;
        }
        return true;
    }
    return false;
}

