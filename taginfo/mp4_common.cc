#include <string>
#include "taginfo.h"
#include "taginfo_internal.h"
#include <mp4file.h>


//#ifdef TAGLIB_WITH_MP4_COVERS
//
string get_mp4_cover_art(TagLib::MP4::Tag * mp4tag, char*& data, int &data_length) {
    data = NULL;
    data_length = 0;
    string mimetype = "";
    
    if(mp4tag && mp4tag->itemListMap().contains("covr")) {
        TagLib::MP4::CoverArtList Covers = mp4tag->itemListMap()[ "covr" ].toCoverArtList();
        
        for(TagLib::MP4::CoverArtList::Iterator it = Covers.begin(); it != Covers.end(); it++) {
            mimetype = "";
            if(it->format() == TagLib::MP4::CoverArt::PNG) {
                mimetype = "image/png";
            }
            else if(it->format() == TagLib::MP4::CoverArt::JPEG) {
                mimetype = "image/jpeg";
            }
            data_length = it->data().size();
            data = new char[data_length];
            memcpy(data, it->data().data(), it->data().size());
            //data = strdup(it->data().data());
            //data_length = it->data().size();
        }
    }
    return mimetype;
}

//
//bool set_mp4_cover_art(TagLib::MP4::Tag * mp4tag, const wxImage * image)
//{
//    if(mp4tag)
//    {
//        if(mp4tag->itemListMap().contains("covr"))
//        {
//            mp4tag->itemListMap().erase("covr");
//        }

//        if(image)
//        {
//            wxMemoryOutputStream ImgOutputStream;
//            if(image && image->SaveFile(ImgOutputStream, wxBITMAP_TYPE_JPEG))
//            {
//                ByteVector ImgData((TagLib::uint) ImgOutputStream.GetSize());
//                ImgOutputStream.CopyTo(ImgData.data(), ImgOutputStream.GetSize());

//                TagLib::MP4::CoverArtList CoverList;
//                TagLib::MP4::CoverArt Cover(TagLib::MP4::CoverArt::JPEG, ImgData);
//                CoverList.append(Cover);
//                mp4tag->itemListMap()[ "covr" ] = CoverList;

//                return true;
//            }
//            return false;
//        }
//        return true;
//    }
//    return false;
//}
//#endif


string get_mp4_lyrics(TagLib::MP4::Tag * mp4tag) {
    if(mp4tag) {
            if(mp4tag->itemListMap().contains("\xa9lyr"))
            return mp4tag->itemListMap()[ "\xa9lyr" ].toStringList().front().toCString(true);
    }
    return "";
}


bool set_mp4_lyrics(TagLib::MP4::Tag * mp4tag, const string &lyrics) {
    if(mp4tag) {
            if(mp4tag->itemListMap().contains("\xa9lyr")) {
            mp4tag->itemListMap().erase("\xa9lyr");
        }
        if(!lyrics.empty()) {
            const TagLib::String Lyrics = lyrics.c_str();
            mp4tag->itemListMap()[ "\xa9lyr" ] = TagLib::StringList(Lyrics);
        }
        return true;
    }
    return false;
}



