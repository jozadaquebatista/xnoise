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

#ifndef APE_INTERNAL_H
#define APE_INTERNAL_H


#include <algorithm>
#include <fstream>
#include <string.h>
#include <vector>
#include <fcntl.h>
#include <unistd.h>


#define APE_TAG_TITLE               "Title" 
#define APE_TAG_SUBTITLE            "Subtitle" 
#define APE_TAG_ARTIST              "Artist" 
#define APE_TAG_ALBUM               "Album" 
#define APE_TAG_DEBUTALBUM          "Debut Album" 
#define APE_TAG_PUBLISHER           "Publisher" 
#define APE_TAG_CONDUCTOR           "Conductor" 
#define APE_TAG_TRACK               "Track"
#define APE_TAG_COMPOSER            "Composer" 
#define APE_TAG_COMMENT             "Comment" 
#define APE_TAG_COPYRIGHT           "Copyright" 
#define APE_TAG_PUBLICATIONRIGHT    "Publicationright" 
#define APE_TAG_FILE                "File" 
#define APE_TAG_EANUPC              "EAN/UPC" 
#define APE_TAG_ISBN                "ISBN" 
#define APE_TAG_CATALOG             "Catalog"
#define APE_TAG_LC                  "LC"
#define APE_TAG_YEAR                "Year" 
#define APE_TAG_RECORDDATE          "Record Date" 
#define APE_TAG_RECORDLOCATION      "Record Location" 
#define APE_TAG_GENRE               "Genre" 
#define APE_TAG_MEDIA               "Media" 
#define APE_TAG_INDEX               "Index" 
#define APE_TAG_RELATED_URL         "Related" 
#define APE_TAG_ISRC                "ISRC" 
#define APE_TAG_ABSTRACT_URL        "Abstract" 
#define APE_TAG_LANGUAGE            "Language" 
#define APE_TAG_BIBLIOGRAPHY_URL    "Bibliography" 
#define APE_TAG_INTROPLAY           "Introplay" 
#define APE_TAG_DUMMY               "Dummy" 

#define APE_TAG_COVER_ART_FRONT     "Cover Art (front)" 
#define APE_TAG_COVER_ART_OTHER     "Cover Art (other)" 
#define APE_TAG_NOTES               "Notes" 
#define APE_TAG_LYRICS              "Lyrics" 
#define APE_TAG_BUY_URL             "Buy URL" 
#define APE_TAG_ARTIST_URL          "Artist URL" 
#define APE_TAG_PUBLISHER_URL       "Publisher URL" 
#define APE_TAG_FILE_URL            "File URL" 
#define APE_TAG_COPYRIGHT_URL       "Copyright URL" 
#define APE_TAG_MJ_METADATA         "Media Jukebox Metadata" 

#define APE_TAG_ALBUMARTIST         "Album Artist" 

#define APE_FLAG_CONTENT_TYPE        0x00000006
#define APE_FLAG_CONTENT_TEXT        0x00000000
#define APE_FLAG_CONTENT_BINARY      0x00000002
#define APE_FLAG_CONTENT_EXTERNAL    0x00000004


namespace TagInfo {
    
    namespace Ape {
        
        typedef struct
        {
            int32_t id;             // should equal 'MAC '
            int16_t version;        // version number * 1000 (3.81 = 3810)
        } ApeCommonHeader;
        
        
        typedef struct
        {
            int32_t id;                         // should equal 'MAC '
            int16_t version;                    // version number * 1000 (3.81 = 3810)
            int32_t descriptor_bytes;           // number of descriptor bytes (allows later expansion of this header)
            int32_t header_bytes;               // number of header APE_HEADER bytes
            int32_t seek_table_bytes;           // number of bytes of the seek table
            int32_t header_data_bytes;          // number of header data bytes (from original file)
            int32_t ape_frame_data_bytes;       // number of bytes of APE frame data
            int32_t ape_frame_data_bytes_high;  // the high order number of APE frame data bytes
            int32_t terminating_data_bytes;     // the terminating data of the file (not including tag data)
            int8_t  file_md5[16];               // the MD5 hash of the file
        } ApeDescriptor;
        
        
        typedef struct
        {
            int16_t compression_level;          // the compression level (see defines I.E. COMPRESSION_LEVEL_FAST)
            int16_t format_flags;               // any format flags (for future use)
            int32_t blocks_per_frame;           // number of audio blocks in one frame
            int32_t final_frame_blocks;         // number of audio blocks in the final frame
            int32_t total_frames;               // the total number of frames
            int16_t bits_per_sample;            // the bits per sample (typically 16)
            int16_t channels;                   // number of channels (1 or 2)
            int32_t sample_rate;                // the sample rate (typically 44100)
        } ApeHeader;
        
        
        typedef struct
        {
            int32_t id;                         // should equal 'MAC '
            int16_t version;                    // version number * 1000 (3.81 = 3810)
            int16_t compression_level;          // the compression level
            int16_t format_flags;               // any format flags (for future use)
            int16_t channels;                   // number of channels (1 or 2)
            int32_t sample_rate;                // the sample rate (typically 44100)
            int32_t header_bytes;               // the bytes after the MAC header that compose the WAV header
            int32_t terminating_bytes;          // the bytes after that raw data (for extended info)
            int32_t total_frames;               // number of frames in the file
            int32_t final_frame_blocks;         // number of samples in the final frame
        } ApeOldHeader;
        
        
        typedef struct  {
            int32_t    magic[2];
            int32_t    version;
            int32_t    length;
            int32_t    item_count;
            int32_t    flags;
            int32_t    reseved[2];
        } ApeHeaderFooter;
    }
}
#endif
