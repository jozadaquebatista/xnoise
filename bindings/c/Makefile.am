AUTOMAKE_OPTIONS = subdir-objects

ACLOCAL_AMFLAGS = \
    ${ACLOCAL_FLAGS}

local_cppflags = -I$(top_srcdir) $(taginfo_includes) -I$(top_srcdir)/taginfo

AM_CPPFLAGS = \
    $(TAGINFO_CFLAGS) \
    $(local_cppflags)

lib_LTLIBRARIES = libtaginfo_c.la

#libtaginfo_c_ladir = $(libdir)/taginfo

libtaginfo_c_la_SOURCES = \
    taginfo_c.cc

libtaginfo_c_includedir = $(includedir)/taginfo
nobase_libtaginfo_c_include_HEADERS = \
    taginfo_c.h

libtaginfo_c_libincludedir = $(libdir)/taginfo/include
#nodist_taginfo_c_libinclude_HEADERS = taginfoconfig.h

libtaginfo_c_la_LIBADD = \
    $(TAGINFO_LIBS) \
    $(top_builddir)/taginfo/libtaginfo.la

pkgconfig_cdir = $(libdir)/pkgconfig
pkgconfig_c_DATA = taginfo_c.pc



DISTCLEANFILES = \
    Makefile.in
