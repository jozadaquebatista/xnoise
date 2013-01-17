#include "ape.h"
#include "ape_internal.h"
#include "taginfo.h"
#include "taginfo_internal.h"


using namespace TagInfo;
using namespace TagInfo::Ape;


ApeInfo::ApeInfo(const string &filename) : Info(), m_ApeFile(filename) {
}


ApeInfo::~ApeInfo() {
}


bool ApeInfo::read(void) {


    ApeTag * Tag = m_ApeFile.get_tag();
    if(Tag) {
            //cout << "title:  " << Tag->get_title()   << endl <<
        //"artist: " << Tag->get_artist()  << endl;
        track_name = Tag->get_title();
        artist = Tag->get_artist();
        album = Tag->get_album();
        genre = Tag->get_genre();
        tracknumber = Tag->get_tracknumber();
        year = Tag->get_year();
        length_seconds = m_ApeFile.get_length();
        bitrate = m_ApeFile.get_bitrate();
        
        comments = Tag->get_item_value(APE_TAG_COMMENT);
        composer = Tag->get_item_value(APE_TAG_COMPOSER);
        disk_str = Tag->get_item_value(APE_TAG_MEDIA);
        album_artist = Tag->get_item_value(APE_TAG_ALBUMARTIST);
        
        if(album_artist.empty())
            album_artist = Tag->get_item_value("AlbumArtist");
        
        return true;
    }
    else {
            printf("Error: Ape file with no tags found\n");
    }
    return false;
}


bool ApeInfo::write(const int changedflag) {
    ApeTag * Tag = m_ApeFile.get_tag();
    if(Tag && (changedflag & CHANGED_DATA_TAGS)) {
            Tag->set_title(track_name);
        Tag->set_artist(artist);
        Tag->set_album(album);
        Tag->set_genre(genre);
        Tag->set_tracknumber(tracknumber);
        Tag->set_year(year);
        Tag->set_item(APE_TAG_COMMENT, comments);
        Tag->set_item(APE_TAG_COMPOSER, composer);
        Tag->set_item(APE_TAG_MEDIA, disk_str);
        Tag->set_item(APE_TAG_ALBUMARTIST, album_artist);
        m_ApeFile.write_tag();
        return true;
    }
    return false;
}


bool ApeInfo::can_handle_lyrics(void) {
    return true;
}


string ApeInfo::get_lyrics(void) {
    ApeTag * Tag = m_ApeFile.get_tag();
    if(Tag)
        return Tag->get_item_value(APE_TAG_LYRICS);
    return "";
}


bool ApeInfo::set_lyrics(const string &lyrics) {
    ApeTag * Tag = m_ApeFile.get_tag();
    if(Tag) {
            Tag->set_item(APE_TAG_LYRICS, lyrics);
        return m_ApeFile.write_tag();
    }
    return false;
}



