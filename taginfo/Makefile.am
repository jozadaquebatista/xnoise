AUTOMAKE_OPTIONS = subdir-objects


ACLOCAL_AMFLAGS = \
    ${ACLOCAL_FLAGS} \
    -I m4

AM_CPPFLAGS = \
    $(TAGINFO_CFLAGS)

lib_LTLIBRARIES = libtaginfo.la

libtaginfo_la_SOURCES = \
    ape_common.cc \
    apeinfo.cc \
    ape_tag.cc \
    ape_file.cc \
    asftaginfo.cc \
    flacinfo.cc \
    id3_common.cc \
    info.cc \
    mp3info.cc \
    mp4_common.cc \
    mp4info.cc \
    mpcinfo.cc \
    ogginfo.cc \
    trueaudioinfo.cc \
    wavpackinfo.cc \
    xiph_common.cc

taginfo_includedir = $(includedir)/taginfo
nobase_taginfo_include_HEADERS = \
    ape.h \
    ape_internal.h \
    taginfo.h \
    taginfo_internal.h

taginfo_libincludedir = $(libdir)/taginfo/include
nodist_taginfo_libinclude_HEADERS = $(top_srcdir)/taginfoconfig.h

libtaginfo_la_LIBADD = \
    $(TAGINFO_LIBS)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = taginfo.pc

DISTCLEANFILES = \
    libtaginfo.la \
    *.lo \
    Makefile.in
