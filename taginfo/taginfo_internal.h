#include "taginfo.h"

#include <stdarg.h>
#include <string>
#include <iostream>
//#include "ape.h"

#include <tag.h>
#include <textidentificationframe.h>
#include <unsynchronizedlyricsframe.h>
#include <fileref.h>
#include <asffile.h>
#include <flacfile.h>
#include <id3v2tag.h>
//#include <mp4file.h>
#include <mpcfile.h>
#include <mpegfile.h>
#include <oggfile.h>
#include <vorbisfile.h>
#include <trueaudiofile.h>
#include <wavpackfile.h>
#include <popularimeterframe.h>

//#include <apetag.h>
#include <id3v2tag.h>


//#include <tag.h>
//#include <attachedpictureframe.h>
//#include <fileref.h>
////#include <id3v2framefactory.h>
//#include <asffile.h>
//#include <mp4file.h>
//#include <oggfile.h>

//#include <xiphcomment.h>

//#include <mp4tag.h>
//#include <apetag.h>
//#include <asftag.h>

//#include <asfattribute.h>

#define BUFFERSIZE 512


using namespace TagLib;
using namespace std;


enum TagInfo::MediaFileType {
    MEDIA_FILE_TYPE_AAC,
    MEDIA_FILE_TYPE_AIF,
    MEDIA_FILE_TYPE_APE,
    MEDIA_FILE_TYPE_ASF,
    MEDIA_FILE_TYPE_FLAC,
    MEDIA_FILE_TYPE_M4A,
    MEDIA_FILE_TYPE_M4B,
    MEDIA_FILE_TYPE_M4P,
    MEDIA_FILE_TYPE_MP3,
    MEDIA_FILE_TYPE_MP4,
    MEDIA_FILE_TYPE_MPC,
    MEDIA_FILE_TYPE_OGA,
    MEDIA_FILE_TYPE_OGG,
    MEDIA_FILE_TYPE_TTA,
    MEDIA_FILE_TYPE_WAV,
    MEDIA_FILE_TYPE_WMA,
    MEDIA_FILE_TYPE_WV
};


inline void split(const string& str, const string& delimiters , vector<string>& tokens) {
    // Skip delimiters at beginning.
    string::size_type lastPos = str.find_first_not_of(delimiters, 0);
    // Find first "non-delimiter".
    string::size_type pos     = str.find_first_of(delimiters, lastPos);
    
    while (string::npos != pos || string::npos != lastPos) {
        // Found a token, add it to the vector.
        tokens.push_back(str.substr(lastPos, pos - lastPos));
        // Skip delimiters.  Note the "not_of"
        lastPos = str.find_first_not_of(delimiters, pos);
        // Find next "non-delimiter"
        pos = str.find_first_of(delimiters, lastPos);
    }
}


inline string format(const char* fmt, ...) {
    char buffer[BUFFERSIZE] = {'\0'};
    va_list vl;
    va_start(vl, fmt);
    int nsize = vsnprintf(buffer, BUFFERSIZE, fmt, vl);
    if(nsize < 0) {
        cout << "Error: String allocation failed in taginfo format function." << endl;
        va_end(vl);
        string ret;
        return ret;
    }
    else {
        va_end(vl);
        string ret(buffer);
        return ret;
    }
}


inline string dirname_of(const string& fname) {
     size_t pos = fname.find_last_of("\\/");
     return (string::npos == pos)
         ? ""
         : fname.substr(0, pos);
}


inline void find_and_replace(string& source, const string& find, const string& replace) {
    size_t fLen = find.size();
    size_t rLen = replace.size();
    
    for (size_t pos = 0; (pos = source.find(find, pos)) != source.npos; pos += rLen)
    {
        source.replace(pos, fLen, replace);
    }
}


inline bool string_disk_to_disk_num(const string &diskstr, int &disknum, int &disktotal) {
    unsigned long Number;
    disknum = 0;
    disktotal = 0;
    string DiskNum = diskstr.substr(0, diskstr.find_first_of("/"));
//    string DiskNum = diskstr.BeforeFirst(wxT('/'));
    if(!DiskNum.empty()) {
        Number = strtoul(DiskNum.data(), NULL, 0);
        
        if(Number > 0) {
            disknum = Number;
            if(diskstr.find("/") != string::npos) {
                DiskNum = diskstr.substr(diskstr.find_first_of("/") + 1);
                //diskstr.AfterFirst(wxT('/'));
                Number = strtoul(DiskNum.data(), NULL, 0);
//                if(DiskNum.ToULong(&Number))
//                {
                disktotal = Number;
//                }
            }
            return true;
        }
    }
    return false;
}

inline int popularity_to_rating(const int rating) {
    if(rating < 0)
        return 0;
    if(rating == 0)
        return 0;
    if(rating < 64)
        return 1;
    if(rating < 128)
        return 2;
    if(rating < 192)
        return 3;
    if(rating < 255)
        return 4;
    return 5;
}


inline int wm_rating_to_rating(const int rating) {
    if(rating <= 0)
        return 0;
    if(rating < 25)
        return 1;
    if(rating < 50)
        return 2;
    if(rating < 75)
        return 3;
    if(rating < 99)
        return 4;
    return 5;
}

int inline rating_to_popularity(const int rating) {
    int Ratings[] = { 0, 0, 1, 64, 128, 192, 255 };
    //printf("Rating: %i => %i\n", rating, Ratings[ rating + 1 ]);
    return Ratings[rating + 1];
}






//////////ID3

void id3v2_check_label_frame(ID3v2::Tag * tagv2, const string& description, const string &value);

string get_typed_id3v2_image(char*& idata, int &idata_length,TagLib::ID3v2::FrameList &framelist,
                             TagLib::ID3v2::AttachedPictureFrame::Type frametype);

bool get_id3v2_image(ID3v2::Tag * tagv2, char*& data, int &data_length);

string get_id3v2_lyrics(ID3v2::Tag * tagv2);
void set_id3v2_lyrics(ID3v2::Tag * tagv2, const string &lyrics);

TagLib::ID3v2::PopularimeterFrame * get_popularity_frame(TagLib::ID3v2::Tag * tag, 
                                                         const TagLib::String &email);

////////// end ID3





////////// XIPH

string get_xiph_comment_lyrics(Ogg::XiphComment * xiphcomment);
bool set_xiph_comment_lyrics(Ogg::XiphComment * xiphcomment, const string &lyrics);

void check_xiph_label_frame(Ogg::XiphComment * xiphcomment, 
                                 const char * description, 
                                 const string &value);

string get_xiph_comment_cover_art(Ogg::XiphComment * xiphcomment, char*& data, int &data_length);
//bool set_xiph_comment_cover_art(Ogg::XiphComment * xiphcomment, const wxImage * image);

////////// end XIPH



////////// MP4

string get_mp4_cover_art(TagLib::MP4::Tag * mp4tag, char*& data, int &data_length);
//bool set_mp4_cover_art(TagLib::MP4::Tag * mp4tag, const wxImage * image);

string get_mp4_lyrics(TagLib::MP4::Tag * mp4tag);
bool set_mp4_lyrics(TagLib::MP4::Tag * mp4tag, const string &lyrics);

////////// end MP4



////////// APE

void check_ape_label_frame(TagLib::APE::Tag * apetag, const char * description, const string &value);

string get_ape_item_image(const TagLib::APE::Item &item, char*& data, int &data_length);
string get_ape_image(TagLib::APE::Tag * apetag, char*& data, int &data_length);

string get_ape_lyrics(APE::Tag * apetag);
bool set_ape_lyrics(APE::Tag * apetag, const string &lyrics);

////////// end APE



