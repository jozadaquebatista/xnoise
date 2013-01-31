
#ifndef TAGINFO_C_H
#define TAGINFO_C_H

//#ifndef DO_NOT_DOCUMENT

#ifdef __cplusplus
extern "C" {
#endif

#ifndef BOOL
#define BOOL int
#endif

/*******************************************************************************
 * [ TagInfo C Binding ]
 *
 * This is an interface to TagInfo's "simple" API, meaning that you can read and
 * modify media files in a generic, but not specialized way.  This is a rough
 * representation of TagInfo::Info.
 *******************************************************************************/


typedef struct { int dummy; } TagInfo_Info;

/*!
 * Creates a TagInfo file based on \a filename.  TagInfo will try to guess the file
 * type.
 *
 * \returns NULL if the file type cannot be determined or the file cannot
 * be opened.
 */
TagInfo_Info *taginfo_info_factory_make(const char *filename);


/*!
 * Frees and closes the file.
 */
void taginfo_info_free(TagInfo_Info *info);

BOOL taginfo_info_read(TagInfo_Info *info);
BOOL taginfo_info_write(TagInfo_Info *info);

char *taginfo_info_get_artist(const TagInfo_Info *info);
void  taginfo_info_set_artist(TagInfo_Info *info, const char *artist);

char *taginfo_info_get_album(const TagInfo_Info *info);
void  taginfo_info_set_album(TagInfo_Info *info, const char *album);

char *taginfo_info_get_title(const TagInfo_Info *info);
void  taginfo_info_set_title(TagInfo_Info *info, const char *title);

char *taginfo_info_get_albumartist(const TagInfo_Info *info);
void  taginfo_info_set_albumartist(TagInfo_Info *info, const char *albumartist);

char *taginfo_info_get_genre(const TagInfo_Info *info);
void  taginfo_info_set_genre(TagInfo_Info *info, const char *genre);

int  taginfo_info_get_tracknumber(const TagInfo_Info *info);
void taginfo_info_set_tracknumber(TagInfo_Info *info, int tracknumber);

int taginfo_info_get_year(const TagInfo_Info *info);
void taginfo_info_set_year(TagInfo_Info *info, int year);

int taginfo_info_get_length(const TagInfo_Info *info);

BOOL taginfo_info_get_has_image(const TagInfo_Info *info);

int taginfo_info_get_bitrate(const TagInfo_Info *info);

char *taginfo_info_get_disk_str(const TagInfo_Info *info);
void  taginfo_info_set_disk_str(TagInfo_Info *info, const char *disk_str);

BOOL taginfo_info_get_is_compilation(const TagInfo_Info *info);
void taginfo_info_set_is_compilation(TagInfo_Info *info, BOOL is_compilation);

BOOL taginfo_info_get_image(const TagInfo_Info *info, char** data, int *data_length);

#ifdef __cplusplus
}
#endif
//#endif /* DO_NOT_DOCUMENT */
#endif
