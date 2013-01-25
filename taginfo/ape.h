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

#ifndef APE_H
#define APE_H

#include <algorithm>
#include <fstream>
#include <string.h>
#include <vector>
#include <fcntl.h>
#include <tag.h>


using namespace std;
using namespace TagLib;


namespace TagInfo {
    
    namespace Ape {
        
        class Item
        {
            public:
                String value;
                String key;
                uint flags;
                
                Item() {};
                
                Item(const String &_key, const String &_val, uint _flags) {
                    this->key   = _key;
                    this->value = _val;
                    this->flags = _flags;
                }
                
                const String & get_key(void) const
                {
                    return key;
                }
                
                const String & get_value(void) const
                {
                    return value;
                }
                
                const uint get_flags(void) const
                {
                    return flags;
                }
                
//                bool operator==(const Item &other);
        };
        
        
        class ApeTag
        {
            protected:
                uint file_length;
                uint offset;
                uint item_count;
                vector<TagInfo::Ape::Item*> items;
            
            public:
                ApeTag(uint _length, uint _offset, uint _items);
                ~ApeTag();
                
                void remove_items(void);
                void remove_item(Item * item);
                void add_item(TagInfo::Ape::Item * item);
                
                Item * get_item(const int position) const;
                Item * get_item(const String &key) const;
                
                String get_item_value(const String &key) const;
                
                void set_item(const String &key, const String &value, uint flags = 0/*CONTENT_TEXT*/);
                void set_item(const String &key, char * data, uint len);
                
                uint get_file_length(void) const;
                uint get_offset(void) const;
                uint get_item_length(void) const;
                uint get_item_count(void) const;
                
                String get_title(void) const;
                void set_title(const String &title);
                
                String get_album(void) const;
                void set_album(const String &album);
                
                String get_artist(void) const;
                void set_artist(const String &artist);
                
                String get_genre(void) const;
                void set_genre(const String &genre);
                
                uint get_tracknumber(void) const;
                void set_tracknumber(const uint track);
                
                uint get_year(void) const;
                void set_year(const uint year);
            
            friend class   ApeFile;
        };
        
        
        class ApeFile
        {
            private:
                String file_name;
                uint length;
                uint bitrate;
                fstream stream;
                ApeTag * apetag;

                void read_header(void);
                void write_header_footer(const uint flags);
                void write_items(void);
                void inline write_number(const int value);

            public:
                ApeFile(const string &filename);
                ~ApeFile();

                bool write_tag(void);

                ApeTag * get_tag()
                {
                    return apetag;
                };

                uint get_bitrate(void)
                {
                    return bitrate;
                }

                uint get_length(void)
                {
                    return length;
                }
        };
    }
}
#endif
