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



using namespace TagInfo;



Info * Info::create_tag_info(const string & filename) {
    map<string,int> ext_map;
    
    ext_map["mp3"]  = MEDIA_FILE_TYPE_MP3;
    ext_map["flac"] = MEDIA_FILE_TYPE_FLAC;
    ext_map["ogg"]  = MEDIA_FILE_TYPE_OGG;
    ext_map["oga"]  = MEDIA_FILE_TYPE_OGA;
    ext_map["mp4"]  = MEDIA_FILE_TYPE_MP4;
    ext_map["m4a"]  = MEDIA_FILE_TYPE_M4A;
    ext_map["m4b"]  = MEDIA_FILE_TYPE_M4B;
    ext_map["m4p"]  = MEDIA_FILE_TYPE_M4P;
    ext_map["aac"]  = MEDIA_FILE_TYPE_AAC;
    ext_map["wma"]  = MEDIA_FILE_TYPE_WMA;
    ext_map["asf"]  = MEDIA_FILE_TYPE_ASF;
    ext_map["ape"]  = MEDIA_FILE_TYPE_APE;
    ext_map["wav"]  = MEDIA_FILE_TYPE_WAV;
    ext_map["aif"]  = MEDIA_FILE_TYPE_AIF;
    ext_map["wv"]   = MEDIA_FILE_TYPE_WV;
    ext_map["tta"]  = MEDIA_FILE_TYPE_TTA;
    ext_map["mpc"]  = MEDIA_FILE_TYPE_MPC;
    
    string fnex = filename.substr(filename.find_last_of(".") + 1);
    if(ext_map[fnex] == 0)
        return NULL;
    
    int format = ext_map[fnex];
    switch(format) {
            case  MEDIA_FILE_TYPE_MP3 :
            return new Mp3Info(filename);
        case  MEDIA_FILE_TYPE_FLAC :
            return new FlacInfo(filename);
        case  MEDIA_FILE_TYPE_OGG :
        case  MEDIA_FILE_TYPE_OGA :
            return new OggInfo(filename);
        case  MEDIA_FILE_TYPE_MP4 :
        case  MEDIA_FILE_TYPE_M4A :
        case  MEDIA_FILE_TYPE_M4B :
        case  MEDIA_FILE_TYPE_M4P :
        case  MEDIA_FILE_TYPE_AAC : 
            return new Mp4Info(filename);
        case  MEDIA_FILE_TYPE_WMA :
        case  MEDIA_FILE_TYPE_ASF :
            return new ASFTagInfo(filename);
        case MEDIA_FILE_TYPE_APE :
            return new ApeInfo(filename);
        case MEDIA_FILE_TYPE_WAV :
        case MEDIA_FILE_TYPE_AIF :
            return new Info(filename);
        case MEDIA_FILE_TYPE_WV : 
            return new WavPackInfo(filename);
        case MEDIA_FILE_TYPE_TTA :
            return new TrueAudioInfo(filename);
        case MEDIA_FILE_TYPE_MPC :
            return new MpcInfo(filename);
        default :
            break;
    }
    return NULL;
}





// Info

Info::Info(const string &filename) {
    
    taglib_file = NULL;
    taglib_tag = NULL;
    
    set_file_name(filename);
    
    tracknumber = 0;
    year = 0;
    length_seconds = 0;
    bitrate = 0;
    rating = -1;
    playcount = 0;
    is_compilation = false;
    has_image = false;
};


Info::~Info() {
    if(taglib_file)
        delete taglib_file;
}


void Info::set_file_name(const string &filename) {
    file_name = filename;
    if(!filename.empty()) {
    //        taglib_file = new TagLib::FileRef(filename.mb_str(wxConvFile), true, TagLib::AudioProperties::Fast);
        taglib_file = new TagLib::FileRef(filename.c_str(), true, TagLib::AudioProperties::Fast);
    }

    if(taglib_file && !taglib_file->isNull()) {
            taglib_tag = taglib_file->tag();
        if(!taglib_tag) {
            printf("Cant get tag object from '%s'\n", filename.c_str());
        }
    }
}


bool Info::read(void) {
    AudioProperties * apro;
    //cout << "Info::read #1" << endl;
    if(taglib_tag) {
            //cout << "Info::read #2" << endl;
        
        track_name  = taglib_tag->title();
        artist = taglib_tag->artist();
        album  = taglib_tag->album();
        genre  = taglib_tag->genre();
        comments   = taglib_tag->comment();
        tracknumber = taglib_tag->track();
        year = taglib_tag->year();
        //cout << "Info::read #3" << endl;
    }
    if(taglib_file && taglib_tag && (apro = taglib_file->audioProperties())) {
            length_seconds = apro->length();
        bitrate = apro->bitrate();
        //m_Samplerate = apro->sampleRate();
        return true;
    }
    return false;
}


bool Info::write(const int changedflag) {
    if(taglib_tag && (changedflag & CHANGED_DATA_TAGS)) {
        taglib_tag->setTitle(track_name);
        taglib_tag->setArtist(artist);
        taglib_tag->setAlbum(album);
        taglib_tag->setGenre(genre);
        taglib_tag->setComment(comments);
        taglib_tag->setTrack(tracknumber); // set the id3v1 track
        taglib_tag->setYear(year);
    }
    
    if(!taglib_file->save()) {
          printf("Tags Save failed for file '%s'\n", file_name.toCString(true));
      return false;
    }
    return true;
}


bool Info::can_handle_images(void) {
    return false;
}

bool Info::get_image(char*& data, int &data_length, ImageType &image_type) {
    data = NULL;
    data_length = 0;
    image_type = IMAGE_TYPE_UNKNOWN;
    return false;
}

bool Info::set_image(char* data, int data_length, ImageType image_type) {
    return false;
}
//            virtual bool get_image(char*& data, int &data_length, &ImageType image_type);
//            virtual bool set_image(char* data, int data_length, ImageType image_type);


//bool Info::can_handle_images(void)
//{
//    return false;
//}

//
//wxImage * Info::get_image(void)
//{
//    return NULL;
//}

//
//bool Info::set_image(const wxImage * image)
//{
//    return false;
//}


bool Info::can_handle_lyrics(void) {
    return false;
}


String Info::get_lyrics(void) {
    return "";
}


bool Info::set_lyrics(const String &lyrics) {
    return false;
}










// Other functions

//wxImage * guTagGetPicture(const String &filename)
//{
//    wxImage * RetVal = NULL;
//    Info * TagInfo = create_tag_info(filename);
//    if(TagInfo)
//    {
//        if(TagInfo->can_handle_images())
//        {
//            RetVal = TagInfo->get_image();
//        }
//        delete TagInfo;
//    }
//    return RetVal;
//}


//bool guTagSetPicture(const String &filename, wxImage * picture)
//{
//    guMainFrame * MainFrame = (guMainFrame *) wxTheApp->GetTopWindow();

//    const guCurrentTrack * CurrentTrack = MainFrame->GetCurrentTrack();
//    if(CurrentTrack && CurrentTrack->m_Loaded)
//    {
//        if(CurrentTrack->file_name == filename)
//        {
//            // Add the pending track change to MainFrame
//            MainFrame->AddPendingUpdateTrack(filename, picture, "", guTRACK_CHANGED_DATA_IMAGES);
//            return true;
//        }
//    }

//    bool RetVal = false;
//    Info * TagInfo = create_tag_info(filename);
//    if(TagInfo)
//    {
//        if(TagInfo->can_handle_images())
//        {
//            RetVal = TagInfo->set_image(picture) && TagInfo->write(guTRACK_CHANGED_DATA_IMAGES);
//        }
//        delete TagInfo;
//    }
//    return RetVal;
//    return false;
//}


//bool guTagSetPicture(const String &filename, const String &imagefile)
//{
//    wxImage Image(imagefile);
//    if(Image.IsOk())
//    {
//        return guTagSetPicture(filename, &Image);
//    }
//    return false;
//}


//String guTagget_lyrics(const String &filename)
//{
//    String RetVal = "";
////    Info * TagInfo = create_tag_info(filename);
////    if(TagInfo)
////    {
////        if(TagInfo->can_handle_lyrics())
////        {
////            RetVal = TagInfo->get_lyrics();
////        }
////        delete TagInfo;
////    }
//    return RetVal;
//}

//
//bool guTagset_lyrics(const String &filename, String &lyrics)
//{
////    guMainFrame * MainFrame = (guMainFrame *) wxTheApp->GetTopWindow();

////    const guCurrentTrack * CurrentTrack = MainFrame->GetCurrentTrack();
////    if(CurrentTrack && CurrentTrack->m_Loaded)
////    {
////        if(CurrentTrack->file_name == filename)
////        {
////            // Add the pending track change to MainFrame
////            MainFrame->AddPendingUpdateTrack(filename, NULL, lyrics, guTRACK_CHANGED_DATA_LYRICS);
////            return true;
////        }
////    }

////    bool RetVal = false;
////    Info * TagInfo = create_tag_info(filename);
////    if(TagInfo)
////    {
////        if(TagInfo->can_handle_lyrics())
////        {
////            RetVal = TagInfo->set_lyrics(lyrics) && TagInfo->write(guTRACK_CHANGED_DATA_LYRICS);
////        }
////        delete TagInfo;
////    }
////    return RetVal;
//    return false;
//}


//void guUpdateTracks(const guTrackArray &tracks, const guImagePtrArray &images,
//                    const wxArrayString &lyrics, const wxArrayInt &changedflags)
//{
//    int Index;
//    int Count = tracks.size();

//    guMainFrame * MainFrame = guMainFrame::GetMainFrame();

//    // Process each Track
//    for(Index = 0; Index < Count; Index++)
//    {
//        // If there is nothign to change continue with next one
//        int ChangedFlag = changedflags[ Index ];
//        if(!ChangedFlag)
//            continue;

//        const guTrack &Track = tracks[ Index ];

//        // Dont allow to edit tags from Cue files tracks
//        if(Track.m_Offset)
//            continue;

//        if(wxFileExists(Track.file_name))
//        {
//            // Prevent write to the current playing file in order to avoid segfaults specially with flac and wma files
//            const guCurrentTrack * CurrentTrack = MainFrame->GetCurrentTrack();
//            if(CurrentTrack && CurrentTrack->m_Loaded)
//            {
//                if(CurrentTrack->file_name == Track.file_name)
//                {
//                    // Add the pending track change to MainFrame
//                    MainFrame->AddPendingUpdateTrack(Track,
//                                                       Index < (int) images.size() ? images[ Index ] : NULL,
//                                                       Index < (int) lyrics.size() ? lyrics[ Index ] : wxT(""),
//                                                       changedflags[ Index ]);
//                    continue;
//                }
//            }

//            Info * TagInfo = create_tag_info(Track.file_name);

//            if(!TagInfo)
//            {
//                guLogError(wxT("There is no handler for the file '%s'"), Track.file_name.c_str());
//                return;
//            }

//            if(ChangedFlag & CHANGED_DATA_TAGS)
//            {
//                TagInfo->track_name = Track.m_SongName;
//                TagInfo->album_artist = Track.album_artist;
//                TagInfo->artist = Track.artist;
//                TagInfo->album = Track.album;
//                TagInfo->genre = Track.genre;
//                TagInfo->tracknumber = Track.m_Number;
//                TagInfo->year = Track.year;
//                TagInfo->composer = Track.composer;
//                TagInfo->comments = Track.comments;
//                TagInfo->disk_str = Track.disk_str;
//            }

//            if(ChangedFlag & guTRACK_CHANGED_DATA_RATING)
//            {
//                TagInfo->rating = Track.rating;
//                TagInfo->playcount = Track.playcount;
//            }

//            if((ChangedFlag & guTRACK_CHANGED_DATA_LYRICS) && TagInfo->can_handle_lyrics())
//            {
//                TagInfo->set_lyrics(lyrics[ Index ]);
//            }

//            if((ChangedFlag & guTRACK_CHANGED_DATA_IMAGES) && TagInfo->can_handle_images())
//            {
//                TagInfo->set_image(images[ Index ]);
//            }

//            TagInfo->write(ChangedFlag);

//            delete TagInfo;
//        }
//        else
//        {
//            guLogMessage(wxT("File not found for edition: '%s'"), Track.file_name.c_str());
//        }
//    }
//}


//void guUpdateImages(const guTrackArray &songs, const guImagePtrArray &images, const wxArrayInt &changedflags)
//{
//    int Index;
//    int Count = images.size();
//    for(Index = 0; Index < Count; Index++)
//    {
//        if(!songs[ Index ].m_Offset && (changedflags[ Index ] & guTRACK_CHANGED_DATA_IMAGES))
//            guTagSetPicture(songs[ Index ].file_name, images[ Index ]);
//    }
//}


//void guUpdateLyrics(const guTrackArray &songs, const wxArrayString &lyrics, const wxArrayInt &changedflags)
//{
//    int Index;
//    int Count = lyrics.size();
//    for(Index = 0; Index < Count; Index++)
//    {
//        if(!songs[ Index ].m_Offset && (changedflags[ Index ] & guTRACK_CHANGED_DATA_LYRICS))
//            guTagset_lyrics(songs[ Index ].file_name, lyrics[ Index ]);
//    }
//}

