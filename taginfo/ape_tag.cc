// -------------------------------------------------------------------------------- //
//	Copyright (C) 2008-2012 J.Rios
//	anonbeat@gmail.com
//
//    This Program is free software; you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation; either version 3, or (at your option)
//    any later version.
//
//    This Program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program; see the file LICENSE.  If not, write to
//    the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
//    http://www.gnu.org/copyleft/gpl.html
//
#include "ape.h"
#include "ape_internal.h"



using namespace TagInfo;
using namespace TagInfo::Ape;


ApeTag::ApeTag(uint length, uint offset, uint nitems)
{
    file_length = length;
    offset = offset;
    item_count = nitems;
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

void ApeTag::add_item(Item * item)
{
    items.push_back(item);
}

Item * ApeTag::get_item(const int pos) const
{
    return items.at(pos);
}

Item * ApeTag::get_item(const string &key) const
{
    Item * item;
    int index;
    int count = items.size();
    for(index = 0; index < count; index++)
    {
        item = items.at(index);
        std::string str1Cpy(key);
        std::string str2Cpy(item->key);
        std::transform(str1Cpy.begin(), str1Cpy.end(), str1Cpy.begin(), ::tolower);
        std::transform(str2Cpy.begin(), str2Cpy.end(), str2Cpy.begin(), ::tolower);
        if(str1Cpy == str2Cpy)
            return item;
    }
    return NULL;
}

string ApeTag::get_item_value(const string &key) const
{
    string RetVal = "";
    Item * item = get_item(key);
    if(item)
    {
        RetVal = item->value;
    }
    return RetVal;
}

void ApeTag::set_item(const string &key, const string &value, uint flags)
{
    Item * item = get_item(key);
    if(item)
    {
        item->value = value;
    }
    else
    {
        item = new Item(key, value, flags);
        items.push_back(item);
    }
}

void ApeTag::set_item(const string &key, char * data, uint len)
{
    Item * item = get_item(key);
    if(item)
    {
        string ustr = data;
        ustr = ustr.substr(0, len);
        item->value = ustr;//wxString::From8BitData(data, len);
    }
    else
    {
        string ustr = data;
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
    for(index = 0; index < count; index++)
    {
        Item * item = items.at(index);

        if(!item->get_value().empty())
        {
            RetVal += 8;
            RetVal += 1;
            RetVal += item->get_key().length();
            RetVal += strlen(item->get_value().c_str());
        }
    }
    return RetVal;
}

uint ApeTag::get_item_count(void) const
{
    uint RetVal = 0;
    int Index;
    int Count = items.size();
    for(Index = 0; Index < Count; Index++)
    {
        Item * item = items.at(Index);

        //printf(wxT("'%s' => '%s'"), item->key.c_str(), item->value.c_str());
        if(!item->value.empty())
        {
//            const wxWX2MBbuf 
            const void* ValueBuf = item->value.c_str();//mb_str(wxConvUTF8);
            if(ValueBuf)
            {
                RetVal++;
            }
        }
    }
    //printf("get_item_count() -> %u \n" , RetVal);
    return RetVal;
}

string ApeTag::get_title(void) const
{
    return get_item_value(APE_TAG_TITLE);
}

void ApeTag::set_title(const string &title)
{
    set_item(APE_TAG_TITLE, title, 0);
}

string ApeTag::get_artist(void) const
{
    return get_item_value(APE_TAG_ARTIST);
}

void ApeTag::set_artist(const string &artist)
{
    set_item(APE_TAG_ARTIST, artist, 0);
}

string ApeTag::get_album(void) const
{
    return get_item_value(APE_TAG_ALBUM);
}

void ApeTag::set_album(const string &album)
{
    set_item(APE_TAG_ALBUM, album, 0);
}

string ApeTag::get_genre(void) const
{
    return get_item_value(APE_TAG_GENRE);
}

void ApeTag::set_genre(const string &genre)
{
    set_item(APE_TAG_GENRE, genre, 0);
}

uint ApeTag::get_tracknumber(void) const
{
    unsigned long Track;
    Track = strtoul(get_item_value(APE_TAG_TRACK).c_str(), NULL, 0);
    return (uint)Track;
}

void ApeTag::set_tracknumber(const uint track)
{
    char* trck;
    if(asprintf (&trck, "%u", track) >= 0) {
        set_item(APE_TAG_TRACK, trck, 0);
        free(trck);
    }
}

uint ApeTag::get_year(void) const
{
    unsigned long Year;
    Year = strtoul(get_item_value(APE_TAG_YEAR).c_str(), NULL, 0);
    return (uint)Year;
}

void ApeTag::set_year(const uint year)
{
    char* yr;
    if(asprintf (&yr, "%u", year) >= 0) {
        set_item(APE_TAG_YEAR, yr, 0);
        free(yr);
    }
}

