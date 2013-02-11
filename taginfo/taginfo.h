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

#ifndef TAGINFO_H
#define TAGINFO_H

#include <string>
#include <iostream>
#include "ape.h"

#include <tag.h>
#include <fileref.h>
#include <asffile.h>
#include <mp4file.h>
#include <oggfile.h>
#include <xiphcomment.h>

#include <apetag.h>
#include <id3v2tag.h>

#define NOT_FOUND -1

using namespace TagLib;
using namespace std;



namespace TagInfo {
    
    enum ChangedData {
        CHANGED_DATA_NONE   = 0,
        CHANGED_DATA_TAGS   = (1 << 0),
        CHANGED_DATA_IMAGES = (1 << 1),
        CHANGED_DATA_LYRICS = (1 << 2),
        CHANGED_DATA_LABELS = (1 << 3),
        CHANGED_DATA_RATING = (1 << 2)
    };
    
    enum ImageType {
        IMAGE_TYPE_UNKNOWN  = 0,
        IMAGE_TYPE_JPEG     = (1 << 0),
        IMAGE_TYPE_PNG      = (1 << 1)
    };
    
    
    class Info
    {
        protected :
            FileRef *       taglib_file;
            Tag *           taglib_tag;
            
            void set_file_name(const string &filename);
        
        
        public:
            String file_name;
            String track_name;
            String genre;
            String artist;
            String album_artist;
            String album;
            String composer;
            String comments;
            int tracknumber;
            int year;
            
            int length_seconds;
            int bitrate;
            
            int playcount;
            int rating;
            String disk_str;
            
            StringList track_labels;
            String track_labels_str;
            
            StringList artist_labels;
            String artist_labels_str;
            
            StringList album_labels;
            String album_labels_str;
            
            bool is_compilation;
            bool has_image;
            
            Info(const string &filename = "");
            ~Info();
            
            virtual bool read(void);
            virtual bool write(const int changedflag);
            
            virtual bool can_handle_images(void);
            virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
            virtual bool set_image(char* data, int data_length, ImageType image_type);
            
            virtual bool can_handle_lyrics(void);
            virtual String get_lyrics(void);
            virtual bool set_lyrics(const String &lyrics);
            
            static Info * create_tag_info(const string &file);
    };


    
    class Mp3Info : public Info {
        protected :
            ID3v2::Tag * taglib_tagId3v2;

        public :
            Mp3Info(const string &filename = "");
            ~Mp3Info();
            
            virtual bool read(void);
            virtual bool write(const int changedflag);
            
            virtual bool can_handle_images(void);
            virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
            virtual bool set_image(char* data, int data_length, ImageType image_type);
            
            virtual bool        can_handle_lyrics(void);
            virtual String    get_lyrics(void);
            virtual bool        set_lyrics(const String &lyrics);
    };
    
    class FlacInfo : public Info {
        protected :
            Ogg::XiphComment * m_XiphComment;
        
        public :
            FlacInfo(const string &filename = "");
            ~FlacInfo();
            
            virtual bool        read(void);
            virtual bool        write(const int changedflag);
            
            virtual bool        can_handle_images(void);
            virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
            virtual bool set_image(char* data, int data_length, ImageType image_type);
            
            virtual bool        can_handle_lyrics(void);
            virtual String    get_lyrics(void);
            virtual bool        set_lyrics(const String &lyrics);
    };

    
    class OggInfo : public Info {
        protected :
            Ogg::XiphComment * m_XiphComment;
        
        public :
            OggInfo(const string &filename = "");
            ~OggInfo();
            
            virtual bool        read(void);
            virtual bool        write(const int changedflag);
            
            virtual bool        can_handle_images(void);
            virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
            virtual bool set_image(char* data, int data_length, ImageType image_type);
            
            virtual bool        can_handle_lyrics(void);
            virtual String    get_lyrics(void);
            virtual bool        set_lyrics(const String &lyrics);
    };

    
    class Mp4Info : public Info {
        protected :
            TagLib::MP4::Tag *  m_Mp4Tag;
        
        public :
            Mp4Info(const string &filename = "");
            ~Mp4Info();
            
            virtual bool        read(void);
            virtual bool        write(const int changedflag);
            
            virtual bool        can_handle_images(void);
            virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
            virtual bool set_image(char* data, int data_length, ImageType image_type);
            
            virtual bool can_handle_lyrics(void);
            virtual String get_lyrics(void);
            virtual bool set_lyrics(const String &lyrics);
    };

    
    class ApeInfo : public Info {
        protected:
            Ape::ApeFile       ape_file;
        
        public:
            ApeInfo(const string &filename = "");
            ~ApeInfo();
            
            virtual bool read(void);
            virtual bool write(const int changedflag);
            
            virtual bool can_handle_lyrics(void);
            virtual String get_lyrics(void);
            virtual bool set_lyrics(const String &lyrics);
    };
    
    class MpcInfo : public Info
    {
      protected :
        TagLib::APE::Tag * taglib_apetag;
        
      public :
        MpcInfo(const string &filename = "");
        ~MpcInfo();
        
        virtual bool read(void);
        virtual bool write(const int changedflag);

        virtual bool can_handle_images(void);
//        virtual bool get_image(char*& data, int &data_length) const;
//        virtual bool set_image(char* data, int data_length);
        virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
        virtual bool set_image(char* data, int data_length, ImageType image_type);
    //    virtual bool can_handle_images(void);
    //    virtual wxImage * get_image(void);
    //    virtual bool set_image(const String * image);
    };

    
    class WavPackInfo : public Info
    {
      protected :
        TagLib::APE::Tag * taglib_apetag;

      public :
        WavPackInfo(const string &filename = "");
        ~WavPackInfo();

        virtual bool read(void);
        virtual bool write(const int changedflag);

        virtual bool can_handle_images(void);
        virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
        virtual bool set_image(char* data, int data_length, ImageType image_type);
//        virtual bool get_image(char*& data, int &data_length) const;
//        virtual bool set_image(char* data, int data_length);
    //    virtual bool can_handle_images(void);
    //    virtual wxImage * get_image(void);
    //    virtual bool set_image(const wxImage * image);
        
        virtual bool can_handle_lyrics(void);
        virtual String get_lyrics(void);
        virtual bool set_lyrics(const String &lyrics);
    };

    
    class TrueAudioInfo : public Info
    {
      protected :
        ID3v2::Tag * taglib_tagId3v2;
        
      public :
        TrueAudioInfo(const string &filename = "");
        ~TrueAudioInfo();
        
        virtual bool read(void);
        virtual bool write(const int changedflag);
        
        virtual bool can_handle_images(void);
        virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
        virtual bool set_image(char* data, int data_length, ImageType image_type);
//        virtual bool get_image(char*& data, int &data_length) const;
//        virtual bool set_image(char* data, int data_length);
    //    virtual bool        can_handle_images(void);
    //    virtual wxImage *   get_image(void);
    //    virtual bool        set_image(const wxImage * image);
        
        virtual bool can_handle_lyrics(void);
        virtual String get_lyrics(void);
        virtual bool set_lyrics(const String &lyrics);
    };

    
    class ASFTagInfo : public Info
    {
      protected :
        ASF::Tag *        m_ASFTag;

      public :
        ASFTagInfo(const string &filename = "");
        ~ASFTagInfo();

        virtual bool read(void);
        virtual bool write(const int changedflag);

        virtual bool can_handle_images(void);
        virtual bool get_image(char*& data, int &data_length, ImageType &image_type);
        virtual bool set_image(char* data, int data_length, ImageType image_type);
//        virtual bool get_image(char*& data, int &data_length) const;
//        virtual bool set_image(char* data, int data_length);
    //    virtual bool        can_handle_images(void);
    //    virtual wxImage *   get_image(void);
    //    virtual bool        set_image(const wxImage * image);
        
        virtual bool can_handle_lyrics(void);
        virtual String get_lyrics(void);
        virtual bool set_lyrics(const String &lyrics);
    };
}
#endif
