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



#define APE_HEADER_MAGIC                0x2043414D  //"MAC "
#define APE_MAGIC_0                     0x54455041  //"APET"
#define APE_MAGIC_1                     0x58454741  //"AGEX"
#define APE_VERSION_1                   1000
#define APE_VERSION_2                   2000

#define APE_FLAG_HAVE_HEADER            0x80000000
#define APE_FLAG_HAVE_FOOTER            0x40000000
#define APE_FLAG_IS_HEADER              0x20000000

#define APE_FLAG_IS_READONLY            0x00000001

#define COMPRESSION_LEVEL_EXTRA_HIGH    4000

using namespace TagInfo;
using namespace TagInfo::Ape;


static uint read_little_endian_uint32(const char * cp)
{
    uint result = cp[3] & 0xff;
    result <<= 8;
    result |= cp[2] & 0xff;
    result <<= 8;
    result |= cp[1] & 0xff;
    result <<= 8;
    result |= cp[0] & 0xff;
    return result;
}


//static void write_little_endian_uint32(char * cp, long i)
//{
//    cp[0] = i & 0xff;
//    i >>= 8;
//    cp[1] = i & 0xff;
//    i >>= 8;
//    cp[2] = i & 0xff;
//    i >>= 8;
//    cp[3] = i & 0xff;
//}


//int compare_items(Item * item1, Item * item2)
//{
//    return item1->get_key() > item2->get_key();
//}







// ApeFile

ApeFile::ApeFile(const string &filename) {
    this->file_name = filename;
    this->apetag = NULL;
    this->length = 0;
    bitrate = 0;
    stream.open(file_name.toCString(true), ios::in|ios::out);
    if(stream.is_open()) {
        read_header();
    }
    else {
        printf("Could not open the ape file %s\n", filename.c_str());
    }
}

ApeFile::~ApeFile() {
    if(stream)
        stream.close();
    if(apetag)
        delete apetag;
}

void inline ApeFile::write_number(const int32_t value) {
    stream.write((const char*)&value, sizeof(value));
}

void ApeFile::write_header_footer(const uint flags) {
    //printf(wxT("Writing header/footer at %08X"), m_File->Tell());
    write_number(APE_MAGIC_0);
    write_number(APE_MAGIC_1);
    write_number(APE_VERSION_2);
    write_number(apetag->get_item_length() + sizeof(ApeHeaderFooter));
    write_number(apetag->get_item_count());
    write_number(flags);
    write_number(0);
    write_number(0);
}


void ApeFile::write_items(void) {
    int index;
    int count = apetag->get_item_count();//items.size();

    char pad = 0;
    for(index = 0; index < count; index++) {
        Item * item = apetag->get_item(index);
        
        if(item->value.isEmpty())
            continue;
        
        const char* ValueBuf = item->value.toCString(false);
        
        if(!ValueBuf)
            continue;
        
        int ValueLen = item->value.size();;
        write_number(ValueLen);
        write_number(item->flags);
        stream.write(item->key.toCString(true), item->key.length());
        stream.write(&pad, sizeof(pad));
        
        if((item->flags & APE_FLAG_CONTENT_TYPE) == APE_FLAG_CONTENT_BINARY) {
            stream.write(item->value.to8Bit().data(), ValueLen);
        }
        else {
            stream.write(ValueBuf, item->value.size());
        }
    }
}

bool ApeFile::write_tag(void) {
    long begin,end;
    stream.seekg(0, ios::beg);
    begin = stream.tellg();
    stream.seekg(0, ios::end);
    end = stream.tellg();
    const uint TagOffset = !apetag->get_offset() ?  apetag->get_file_length() : apetag->get_offset();

    stream.seekp(TagOffset, ios::beg);
    // write header
    if(stream.tellp() != TagOffset) {
        printf("Seek for header failed %ld target pos %u\n", (long)stream.tellp(), TagOffset);
    }
    write_header_footer(APE_FLAG_IS_HEADER |
                        APE_FLAG_HAVE_HEADER
    );
    write_items();
    write_header_footer(APE_FLAG_HAVE_HEADER);
    
    uint CurPos = stream.tellp();
    
    stream.flush();
    stream.close();
    
    const char* fname = file_name.toCString(true);
    int fd = open(fname, O_RDWR, "rw+");
    if(CurPos < apetag->get_file_length()) {
        int result = ftruncate(fd, CurPos);
        if(result) {
            printf("FAILED Truncating file %s\n", file_name.toCString(true));
        }
    }
    close(fd);
    return true;
}


void ApeFile::read_header(void) {
    long begin,end;
    begin = stream.tellg();
    stream.seekg(0, ios::end);
    end = stream.tellg();
    const long FileLength = end - begin;
    //printf("FileLength:  %lu\n", FileLength);
    //printf("sizeof(ApeCommonHeader):  %u\n", sizeof(ApeCommonHeader));
    //printf("sizeof(ApeDescriptor):  %u\n", sizeof(ApeDescriptor));
    //printf("sizeof(ApeHeader):  %u\n", sizeof(ApeHeader));
    //printf("sizeof(ApeOldHeader):  %u\n", sizeof(ApeOldHeader));
    //printf("sizeof(ApeHeaderFooter):  %u\n", sizeof(ApeHeaderFooter));
    
    ApeCommonHeader common_header;
    stream.seekg (0, ios::beg);
    stream.read((char*)&common_header, sizeof(ApeCommonHeader));
    if(common_header.id != APE_HEADER_MAGIC) {
        printf("This is not a valid ape file %08x . APE_HEADER_MAGIC:  %08x\n", common_header.id, APE_HEADER_MAGIC);
        return;
    }
    // New header format
    if(common_header.version >= 3980) {
        //std::cout << "NEW HEADER FORMAT: " << common_header.version << std::endl;
        ApeDescriptor  Descriptor;
        ApeHeader      header;
        stream.seekg(0, ios::beg);
        
        stream.read((char*) &Descriptor, sizeof(ApeDescriptor));
        int ReadCnt = stream.gcount();
        if((ReadCnt - Descriptor.descriptor_bytes) > 0)
            stream.seekg(Descriptor.descriptor_bytes - ReadCnt, ios::cur);
        
        stream.read((char*) &header, sizeof(ApeHeader));
        ReadCnt = stream.gcount();
        if((ReadCnt - Descriptor.header_bytes) > 0)
            stream.seekg(Descriptor.header_bytes - ReadCnt, ios::cur);
        
        length = int(double(((header.total_frames - 1) * header.blocks_per_frame) + 
            double(header.final_frame_blocks)) / double(header.sample_rate)) * 1000;
        //printf("TotalFrames      : %u\n", header.total_frames);
        //printf("blocks_per_frame   : %u\n", header.blocks_per_frame);
        //printf("FinalFrameBlocks : %u\n", header.final_frame_blocks);
        //printf("SampleRate       : %u\n", header.sample_rate);
    }
    else {
        // Old header format
        //std::cout << "OLD HEADER FORMAT" << std::endl;
        ApeOldHeader header;
        stream.seekg(0, ios::beg);
        
        stream.read((char*) &header, sizeof(ApeOldHeader));
        
        uint blocks_per_frame = ((header.version >= 3900) || ((header.version >= 3800) && (header.compression_level == COMPRESSION_LEVEL_EXTRA_HIGH))) ? 73728 : 9216;
        if((header.version >= 3950))
            blocks_per_frame = 73728 * 4;
        
        //printf("TotalFrames      : %u\n", header.total_frames);
        //printf("blocks_per_frame   : %u\n", blocks_per_frame);
        //printf("FinalFrameBlocks : %u\n", header.final_frame_blocks);
        //printf("SampleRate       : %u\n", header.sample_rate);
        
        length = int(double(((header.total_frames - 1) * blocks_per_frame) + header.final_frame_blocks)
                             / double(header.sample_rate)) * 1000;
        
    }
    
    bitrate = length ? int((double(FileLength) * double(8)) / double(length)) : 0;

    if(FileLength < sizeof(ApeHeaderFooter)) {
        printf("file too short to contain an ape tag");
        return;
    }
    
    // read footer
    ApeHeaderFooter footer;
    stream.seekg(FileLength - sizeof(ApeHeaderFooter), ios::beg);
    
    stream.read((char*) &footer, sizeof(ApeHeaderFooter));
    
    if(footer.magic[0] != APE_MAGIC_0 || footer.magic[1] != APE_MAGIC_1) {
        printf("file does not contain footer tag\n");
        printf("footer.magic[0]: %08x\n", footer.magic[0]);
        printf("footer.magic[1]: %08x\n", footer.magic[1]);
        apetag = new ApeTag(FileLength, FileLength, 0);
        return;
    }

    if(footer.version != APE_VERSION_2)
    {
        printf("Unsupported footer tag version %i\n", footer.version);
        return;
    }
    
    //printf("\nFound ApeFooter tag footer version: %i  length: %i  items: %i  flags: %08x \n",
     //         footer.version, footer.length, footer.item_count, footer.flags );

    if(FileLength < footer.length) {
        printf("ApeTag bigger than file\n");
        return;
    }
    
    // read header if any
    bool have_header = false;
    
    if(FileLength >= footer.length + sizeof(ApeHeaderFooter)) {
        stream.seekg(FileLength - (footer.length + sizeof(ApeHeaderFooter)), ios::beg);
        ApeHeaderFooter header;
        
        stream.read((char*) &header, sizeof(ApeHeaderFooter));
        
        if(header.magic[0] == APE_MAGIC_0 && header.magic[1] == APE_MAGIC_1) {
            have_header = true;
            
            if(header.version != footer.version || 
               header.length != footer.length || 
               header.item_count != footer.item_count) {
                printf("footer header/footer data mismatch %d -> %d   ; %d -> %d\n", header.version, footer.version, header.length, footer.length);
            }
            //printf("\nFound ApeFooter tag header version: %i  length: %i  items: %i  flags: %08x\n",
            //      header.version, header.length, header.item_count, header.flags );

        }
    }
    
    //printf("\nXXX filelength: %u, %u, %u , %u\n", FileLength,
    //                      footer.length, have_header * sizeof(ApeHeaderFooter),
    //                      footer.item_count);
    apetag = new ApeTag(FileLength,
                        FileLength - footer.length - ((int)have_header * sizeof(ApeHeaderFooter)),
                        footer.item_count);
    
    // read and process tag data
    stream.seekg(- (int) footer.length, ios::end);
    
    char * const items_string_buffer = new char[footer.length];
    stream.read((char*) items_string_buffer, footer.length);
    char * CurBufPos = items_string_buffer;
    //printf("\nFound a valid ape footer with %i items and %i bytes length\n", footer.item_count, footer.length );
    int index;
    for(index = 0; index < (int) footer.item_count; index++) {
        String Value;
        String Key;
        const uint ValueLen = read_little_endian_uint32(CurBufPos);
        CurBufPos += sizeof(ValueLen);

        if(ValueLen > (footer.length - (items_string_buffer - CurBufPos)))   {
            printf("Aborting reading of corrupt ape tag %u > %ld\n", ValueLen, (footer.length - (items_string_buffer - CurBufPos)));
            apetag->remove_items();
            break;
        }
        
        const uint ItemFlags = read_little_endian_uint32(CurBufPos);
        CurBufPos += sizeof(ItemFlags);
        
        Key = CurBufPos;
        CurBufPos += 1 + strlen(Key.toCString(false));// Key.length();
        
        if((ItemFlags & APE_FLAG_CONTENT_TYPE) == APE_FLAG_CONTENT_BINARY) {
            char subbuff[ValueLen + 1];
            memcpy( subbuff, CurBufPos, ValueLen );
            subbuff[ValueLen] = '\0';
            Value = (char*)&subbuff;//::strdup(Value.toCString(true));
        }
        else {
            Value = String(::strndup(CurBufPos, ValueLen));
        }
        
        CurBufPos += ValueLen;
        
        Item * itn = new Item(Key, Value, ItemFlags);
        
        apetag->add_item(itn);
    }
    delete items_string_buffer;
}

