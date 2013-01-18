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


#include <FLAC/metadata.h>
#include <FLAC/format.h>

using namespace TagInfo;


FlacInfo::FlacInfo(const string &filename) : Info(filename) {
    if(taglib_file && !taglib_file->isNull()) {
            m_XiphComment = ((TagLib::FLAC::File *) taglib_file->file())->xiphComment();
    }
    else
        m_XiphComment = NULL;
}


FlacInfo::~FlacInfo() {
}


bool FlacInfo::read(void) {
    if(Info::read()) {
            if(m_XiphComment) {
            if(m_XiphComment->fieldListMap().contains("COMPOSER")) {
                composer = m_XiphComment->fieldListMap()["COMPOSER"].front().toCString(true);
            }
            if(m_XiphComment->fieldListMap().contains("DISCNUMBER")) {
                disk_str = m_XiphComment->fieldListMap()["DISCNUMBER"].front().toCString(true);
            }
            if(m_XiphComment->fieldListMap().contains("COMPILATION")) {
                is_compilation = m_XiphComment->fieldListMap()["COMPILATION"].front().toCString(true) == (char*)"1";
            }
            if(m_XiphComment->fieldListMap().contains("ALBUMARTIST")) {
                album_artist = m_XiphComment->fieldListMap()["ALBUMARTIST"].front().toCString(true);
            }
            else if(m_XiphComment->fieldListMap().contains("ALBUM ARTIST")) {
                album_artist = m_XiphComment->fieldListMap()["ALBUM ARTIST"].front().toCString(true);
            }
            // Rating
            if(m_XiphComment->fieldListMap().contains("RATING")) {
                long Rating = 0;
//                if(m_XiphComment->fieldListMap()["RATING"].front().toCString(true).ToLong(&Rating))
                Rating = atol(m_XiphComment->fieldListMap()["RATING"].front().toCString(true));
                if(Rating)
                {
                    if(Rating > 5)
                    {
                        rating = popularity_to_rating(Rating);
                    }
                    else
                    {
                        rating = Rating;
                    }
                }
            }
            if(m_XiphComment->fieldListMap().contains("PLAY_COUNTER")) {
                long PlayCount = 0;
                PlayCount = atol(m_XiphComment->fieldListMap()["PLAY_COUNTER"].front().toCString(true));
//                if(m_XiphComment->fieldListMap()["PLAY_COUNTER"].front().toCString(true).ToLong(&PlayCount))
//                {
                playcount = PlayCount;
//                }
            }
            // Labels
            if(track_labels.size() == 0) {
                if(m_XiphComment->fieldListMap().contains("TRACK_LABELS"))
                {
                    track_labels_str = m_XiphComment->fieldListMap()["TRACK_LABELS"].front().toCString(true);
                    //guLogMessage(wxT("*Track Label: '%s'\n"), track_labels_str.c_str());
                    split(track_labels_str, "|" , track_labels);
                }
            }
            if(artist_labels.size() == 0) {
                if(m_XiphComment->fieldListMap().contains("ARTIST_LABELS"))
                {
                    artist_labels_str = m_XiphComment->fieldListMap()["ARTIST_LABELS"].front().toCString(true);
                    //guLogMessage(wxT("*Artist Label: '%s'\n"), artist_labels_str.c_str());
                    split(artist_labels_str, "|" , artist_labels);
                }
            }
            if(album_labels.size() == 0) {
                if(m_XiphComment->fieldListMap().contains("ALBUM_LABELS"))
                {
                    album_labels_str = m_XiphComment->fieldListMap()["ALBUM_LABELS"].front().toCString(true);
                    //guLogMessage(wxT("*Album Label: '%s'\n"), album_labels_str.c_str());
                    split(album_labels_str, "|" , album_labels);
                }
            }
            return true;
        }
    }
    return false;
}



bool FlacInfo::write(const int changedflag) {
    if(m_XiphComment) {
            if(changedflag & CHANGED_DATA_TAGS) {
            m_XiphComment->addField("DISCNUMBER", disk_str.c_str());
            m_XiphComment->addField("COMPOSER", composer.c_str());
            
            m_XiphComment->addField("COMPILATION", format("%d", (int)is_compilation).c_str());
//            char* str;
//            if(asprintf (&str, "%d", (int)is_compilation) >= 0) {
//                m_XiphComment->addField("COMPILATION", str);
//                free(str);
//            }
            
            
            m_XiphComment->addField("ALBUMARTIST", album_artist.c_str());
        }

        if(changedflag & CHANGED_DATA_RATING) {
            m_XiphComment->addField("RATING", format("%u", rating_to_popularity(rating)).c_str());
            m_XiphComment->addField("PLAY_COUNTER", format("%u", playcount).c_str());
//            char* str;
//            if(asprintf (&str, "%u" , rating_to_popularity(rating)) >= 0) {
//                m_XiphComment->addField("RATING", str);
//                free(str);
//            }
//            
//            if(asprintf (&str, "%u" , playcount) >= 0) {
//                m_XiphComment->addField("PLAY_COUNTER", str);
//                free(str);
//            }
        }

        if(changedflag & CHANGED_DATA_LABELS) {
            // The Labels
            check_xiph_label_frame(m_XiphComment, "ARTIST_LABELS", artist_labels_str);
            check_xiph_label_frame(m_XiphComment, "ALBUM_LABELS", album_labels_str);
            check_xiph_label_frame(m_XiphComment, "TRACK_LABELS", track_labels_str);
        }
    }
    return Info::write(changedflag);
}


bool FlacInfo::can_handle_images(void) {
    return true;
}

bool FlacInfo::get_image(char*& data, int &data_length) const {
    data = NULL;
    data_length = 0;
    string mime = "";
    FLAC__Metadata_SimpleIterator * iter = FLAC__metadata_simple_iterator_new();
    if(iter) {
            if(FLAC__metadata_simple_iterator_init(iter, file_name.data(), true, false)) {
            while(!data && FLAC__metadata_simple_iterator_next(iter)) {
                if(FLAC__metadata_simple_iterator_get_block_type(iter) == FLAC__METADATA_TYPE_PICTURE)
                {
                    FLAC__StreamMetadata * block = FLAC__metadata_simple_iterator_get_block(iter);
                    
                    if(block->data.picture.type == FLAC__STREAM_METADATA_PICTURE_TYPE_FRONT_COVER)
                    {
                        FLAC__StreamMetadata_Picture * PicInfo = &block->data.picture;
                        data = strdup((const char*)PicInfo->data);
                        data_length = PicInfo->data_length;
                        mime = PicInfo->mime_type;
                    }
                    FLAC__metadata_object_delete(block);
                }
            }
        }
        FLAC__metadata_simple_iterator_delete(iter);
    }
    if(data == NULL || data_length <= 0 || mime == "")
        return false;
    else
        return true;
}

bool FlacInfo::set_image(char* data, int data_length) {
    return false;
}


//bool FlacInfo::can_handle_images(void)
//{
//    return true;
//}

//
//wxImage * FlacInfo::get_image(void)
//{
//    wxImage * CoverImage = NULL;

//    FLAC__Metadata_SimpleIterator * iter = FLAC__metadata_simple_iterator_new();
//    if(iter)
//    {
//        if(FLAC__metadata_simple_iterator_init(iter, file_name.data(), true, false))
//        {
//            while(!CoverImage && FLAC__metadata_simple_iterator_next(iter))
//            {
//                if(FLAC__metadata_simple_iterator_get_block_type(iter) == FLAC__METADATA_TYPE_PICTURE)
//                {
//                    FLAC__StreamMetadata * block = FLAC__metadata_simple_iterator_get_block(iter);

//                    if(block->data.picture.type == FLAC__STREAM_METADATA_PICTURE_TYPE_FRONT_COVER)
//                    {
//                        wxMemoryOutputStream ImgOutStream;

//                        FLAC__StreamMetadata_Picture * PicInfo = &block->data.picture;

//                        ImgOutStream.write(PicInfo->data, PicInfo->data_length);
//                        wxMemoryInputStream ImgInputStream(ImgOutStream);
//                        CoverImage = new wxImage(ImgInputStream, wxString(PicInfo->mime_type, wxConvUTF8));

//                        if(CoverImage)
//                        {
//                            if(!CoverImage->IsOk())
//                            {
//                                delete CoverImage;
//                                CoverImage = NULL;
//                            }
//                        }
//                    }

//                    FLAC__metadata_object_delete(block);
//                }
//            }
//        }

//        FLAC__metadata_simple_iterator_delete(iter);
//    }

//    return CoverImage;
//}

//
//bool FlacInfo::set_image(const wxImage * image)
//{
//    bool RetVal = false;
//    FLAC__Metadata_Chain * Chain;
//    FLAC__Metadata_Iterator * Iter;

//    Chain = FLAC__metadata_chain_new();
//    if(Chain)
//    {
//        if(FLAC__metadata_chain_read(Chain, file_name.data()))
//        {
//            Iter = FLAC__metadata_iterator_new();
//            if(Iter)
//            {
//                FLAC__metadata_iterator_init(Iter, Chain);

//                while(FLAC__metadata_iterator_next(Iter))
//                {
//                    if(FLAC__metadata_iterator_get_block_type(Iter) == FLAC__METADATA_TYPE_PICTURE)
//                    {
//                        FLAC__StreamMetadata * Picture = FLAC__metadata_iterator_get_block(Iter);
//                        if(Picture->data.picture.type ==  FLAC__STREAM_METADATA_PICTURE_TYPE_FRONT_COVER)
//                        {
//                            //
//                            FLAC__metadata_iterator_delete_block(Iter, true);
//                        }
//                    }
//                }

//                wxMemoryOutputStream ImgOutputStream;
//                if(image && image->SaveFile(ImgOutputStream, wxBITMAP_TYPE_JPEG))
//                {
//                    FLAC__byte * CoverData = (FLAC__byte *) malloc(ImgOutputStream.GetSize());
//                    if(CoverData)
//                    {
//                        const char * PicErrStr;

//                        ImgOutputStream.CopyTo(CoverData, ImgOutputStream.GetSize());

//                        //
//                        FLAC__StreamMetadata * Picture;
//                        Picture = FLAC__metadata_object_new(FLAC__METADATA_TYPE_PICTURE);
//                        Picture->data.picture.type = FLAC__STREAM_METADATA_PICTURE_TYPE_FRONT_COVER;
//                        FLAC__metadata_object_picture_set_mime_type(Picture,  (char *) "image/jpeg", TRUE);

//                        //FLAC__metadata_object_picture_set_description(Picture, (char *) "", TRUE);
//                        Picture->data.picture.width  = image->GetWidth();
//                        Picture->data.picture.height = image->GetHeight();
//                        Picture->data.picture.depth  = 0;

//                        FLAC__metadata_object_picture_set_data(Picture, CoverData, (FLAC__uint32) ImgOutputStream.GetSize(), FALSE);

//                        if(FLAC__metadata_object_picture_is_legal(Picture, &PicErrStr))
//                        {
//                            FLAC__metadata_iterator_insert_block_after(Iter, Picture);
//                        }
//                        else
//                        {
//                            FLAC__metadata_object_delete(Picture);
//                        }
//                    }
//                }

//                FLAC__metadata_chain_sort_padding(Chain);
//                if(!FLAC__metadata_chain_write(Chain, TRUE, TRUE))
//                {
//                    guLogError(wxT("Could not save the FLAC file"));
//                }
//                else
//                {
//                    RetVal = true;
//                }
//            }
//            else
//            {
//                guLogError(wxT("Could not create the FLAC Iterator."));
//            }
//        }
//        else
//        {
//            guLogError(wxT("Could not read the FLAC metadata."));
//        }

//        FLAC__metadata_chain_delete(Chain);
//    }
//    else
//    {
//        guLogError(wxT("Could not create a FLAC chain."));
//    }
//    return RetVal;
//}


bool FlacInfo::can_handle_lyrics(void) {
    return true;
}


string FlacInfo::get_lyrics(void) {
    return get_xiph_comment_lyrics(m_XiphComment);
}


bool FlacInfo::set_lyrics(const string &lyrics) {
    return set_xiph_comment_lyrics(m_XiphComment, lyrics);
}


