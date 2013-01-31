#include "taginfo.h"

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "taginfo_c.h"

using namespace TagInfo;
using namespace TagLib;

TagInfo_Info * taginfo_info_factory_make(const char *filename) {
    return reinterpret_cast<TagInfo_Info *>(Info::create_tag_info(filename));
}

void taginfo_info_free(TagInfo_Info *info) {
    delete reinterpret_cast<Info *>(info);
}

BOOL taginfo_info_read(TagInfo_Info *info) {
    Info *i = reinterpret_cast<Info *>(info);
    return i->read();
}

BOOL taginfo_info_write(TagInfo_Info *info) {
    Info *i = reinterpret_cast<Info *>(info);
    return i->write(CHANGED_DATA_TAGS); //TODO
}



char *taginfo_info_get_artist(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    char *s = ::strdup(i->artist.toCString(true));
    return s;
}
void taginfo_info_set_artist(TagInfo_Info *info, const char *artist) {
    Info *i = reinterpret_cast<Info *>(info);
    i->artist = String(artist, String::UTF8);
}



char *taginfo_info_get_album(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    char *s = ::strdup(i->album.toCString(true));
    return s;
}
void taginfo_info_set_album(TagInfo_Info *info, const char *album) {
    Info *i = reinterpret_cast<Info *>(info);
    i->album = String(album, String::UTF8);
}



char *taginfo_info_get_title(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    char *s = ::strdup(i->track_name.toCString(true));
    return s;
}
void taginfo_info_set_title(TagInfo_Info *info, const char *title) {
    Info *i = reinterpret_cast<Info *>(info);
    i->track_name = String(title, String::UTF8);
}


char *taginfo_info_get_albumartist(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    char *s = ::strdup(i->album_artist.toCString(true));
    return s;
}
void taginfo_info_set_albumartist(TagInfo_Info *info, const char *albumartist) {
    Info *i = reinterpret_cast<Info *>(info);
    i->album_artist = String(albumartist, String::UTF8);
}



char *taginfo_info_get_genre(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    char *s = ::strdup(i->genre.toCString(true));
    return s;
}
void taginfo_info_set_genre(TagInfo_Info *info, const char *genre) {
    Info *i = reinterpret_cast<Info *>(info);
    i->genre = String(genre, String::UTF8);
}



int taginfo_info_get_tracknumber(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    return i->tracknumber;
}
void taginfo_info_set_tracknumber(TagInfo_Info *info, int tracknumber) {
    Info *i = reinterpret_cast<Info *>(info);
    i->tracknumber = tracknumber;
}



int taginfo_info_get_year(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    return i->year;
}
void taginfo_info_set_year(TagInfo_Info *info, int year) {
    Info *i = reinterpret_cast<Info *>(info);
    i->year = year;
}


int taginfo_info_get_bitrate(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    return i->bitrate;
}


int taginfo_info_get_length(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    int s = i->length_seconds;
    return s;
}

BOOL taginfo_info_get_has_image(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    bool image_available = i->has_image;
    return image_available;
}


char *taginfo_info_get_disk_str(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    char *s = ::strdup(i->disk_str.toCString(true));
    return s;
}
void taginfo_info_set_disk_str(TagInfo_Info *info, const char *disk_str) {
    Info *i = reinterpret_cast<Info *>(info);
    i->disk_str = String(disk_str, String::UTF8);
}



BOOL taginfo_info_get_is_compilation(const TagInfo_Info *info) {
    const Info *i = reinterpret_cast<const Info *>(info);
    BOOL s = i->is_compilation;
    return s;
}
void taginfo_info_set_is_compilation(TagInfo_Info *info, BOOL is_compilation) {
    Info *i = reinterpret_cast<Info *>(info);
    i->is_compilation = (bool)is_compilation;
}

//            virtual bool get_image(char*& data, int &data_length);
BOOL taginfo_info_get_image(const TagInfo_Info *info, char** data, int* data_length) {
    const Info *i = reinterpret_cast<const Info *>(info);
    bool v = i->get_image((*data), (*data_length));
    return v;
}

