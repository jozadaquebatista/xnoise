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

#include "ape.h"
#include "ape_internal.h"



using namespace TagInfo;
using namespace TagInfo::Ape;


ApeTag::ApeTag(uint _length, uint _offset, uint _nitems)
{
    this->file_length = _length;
    this->offset = _offset;
    this->item_count = _nitems;
    this->items.clear();
//    items = new ItemArray(compare_items);
}

ApeTag::~ApeTag()
{
    if(items.size() > 0) {
        for (std::vector<Item*>::iterator it = items.begin() ; it != items.end(); ++it)
            delete *it;
    }
    items.clear();
}

void ApeTag::remove_items()
{
    for (std::vector<Item*>::iterator it = items.begin() ; it != items.end(); ++it)
        delete *it;
    items.clear();
}

void ApeTag::remove_item(Item * item)
{
    int j = 0;
    for (std::vector<Item*>::iterator it = items.begin() ; it != items.end(); ++it) {
        if(*it == item) {
            items.erase(it);
            break;
        }
        j++;
        if(j == (int)items.size())
            printf("Could not find the item in the ape tags");
    }
    delete item;
}

void ApeTag::add_item(TagInfo::Ape::Item * item)
{
    items.push_back(item);
}

Item * ApeTag::get_item(const int pos) const
{
    return items.at(pos);
}

Item * ApeTag::get_item(const String &key) const
{
    Item * item;
    int index;
    int count = items.size();
    for(index = 0; index < count; index++) {
        item = items.at(index);
//        String str1Cpy(key);
//        String str2Cpy(item->key);
//        std::transform(str1Cpy.begin(), str1Cpy.end(), str1Cpy.begin(), ::tolower);
//        std::transform(str2Cpy.begin(), str2Cpy.end(), str2Cpy.begin(), ::tolower);
        if(key == item->key)
            return item;
    }
    return NULL;
}

String ApeTag::get_item_value(const String &key) const
{
    String RetVal = "";
    Item * item = get_item(key);
    if(item) {
        RetVal = item->get_value();
    }
    return RetVal;
}

void ApeTag::set_item(const String &key, const String &value, uint flags) {
    Item * item = get_item(key);
    if(item) {
        item->value = value;
    }
    else {
        item = new Item(key, value, flags);
        items.push_back(item);
    }
}

void ApeTag::set_item(const String &key, char * data, uint len)
{
    Item * item = get_item(key);
    if(item) {
        String ustr = data;
        ustr = ustr.substr(0, len);
        item->value = ustr;//wxString::From8BitData(data, len);
    }
    else {
        String ustr = data;
        ustr = ustr.substr(0, len);
        item = new Item(key, ustr, APE_FLAG_CONTENT_BINARY);
        items.push_back(item);
    }
}

uint ApeTag::get_file_length(void) const
{
    return file_length;
}

uint ApeTag::get_offset(void) const
{
    return offset;
}

uint ApeTag::get_item_length(void) const
{
    uint RetVal = 0;
    int index;
    int count = items.size();
    for(index = 0; index < count; index++) {
        Item * item = items.at(index);
        
        if(!item->get_value().isEmpty())
        {
            RetVal += 8;
            RetVal += 1;
            RetVal += item->get_key().length();
            RetVal += item->get_value().length();
        }
    }
    return RetVal;
}

uint ApeTag::get_item_count(void) const
{
    uint RetVal = 0;
    int Index;
    int Count = items.size();
    for(Index = 0; Index < Count; Index++) {
        Item * item = items.at(Index);
        
        if(!item->get_value().isEmpty()) {
            RetVal++;
        }
    }
    return RetVal;
}

String ApeTag::get_title(void) const
{
    return get_item_value(APE_TAG_TITLE);
}

void ApeTag::set_title(const String &title)
{
    set_item(APE_TAG_TITLE, title, 0);
}

String ApeTag::get_artist(void) const
{
    return get_item_value(APE_TAG_ARTIST);
}

void ApeTag::set_artist(const String &artist)
{
    set_item(APE_TAG_ARTIST, artist, 0);
}

String ApeTag::get_album(void) const
{
    return get_item_value(APE_TAG_ALBUM);
}

void ApeTag::set_album(const String &album)
{
    set_item(APE_TAG_ALBUM, album, 0);
}

String ApeTag::get_genre(void) const
{
    return get_item_value(APE_TAG_GENRE);
}

void ApeTag::set_genre(const String &genre)
{
    set_item(APE_TAG_GENRE, genre, 0);
}

uint ApeTag::get_tracknumber(void) const
{
    String ret = get_item_value(APE_TAG_TRACK);
    int i = 0;
    unsigned long Track;
    if((i = ret.find("/")) < 0) {
        Track = strtoul(ret.toCString(false), NULL, 0);
        return (uint)Track;
    }
    else {
        String first = ret.substr(0, i);
        Track = strtoul(first.toCString(false), NULL, 0);
        return (uint)Track;
    }
}

void ApeTag::set_tracknumber(uint track)//(const uint track)
{
    char* trck;
    if(asprintf (&trck, "%u", track) >= 0) {
        String tstr = trck;
        set_item(APE_TAG_TRACK, tstr, 0);
        free(trck);
    }
}

uint ApeTag::get_year(void) const
{
    unsigned long Year;
    Year = strtoul(get_item_value(APE_TAG_YEAR).toCString(true), NULL, 0); //JM ******
    return (uint)Year;
}

void ApeTag::set_year(const uint year)
{
    char* yr;
    if(asprintf (&yr, "%u", year) >= 0) {
        String ystr = yr;
        set_item(APE_TAG_YEAR, ystr, 0);
        free(yr);
    }
}

