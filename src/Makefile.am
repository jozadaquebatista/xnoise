NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

bin_PROGRAMS = xnoise

INCLUDES = \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
    $(XNOISE_CFLAGS) \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    $(NULL)

xnoise_SOURCES = \
    xnoise.vala \
    $(NULL)

VALAFLAGS = \
    --basedir $(top_srcdir)/src \
    --thread \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg xnoise-1.0 \
    --vapidir $(top_srcdir)/vapi \
    --pkg config \
    --pkg linux \
    $(NULL)

xnoise_LDADD = \
    $(XNOISE_LIBS) \
    -lgstpbutils-0.10 \
    $(top_builddir)/libxnoise/libxnoise.la \
    $(NULL)

xnoise_LDFLAGS = -export-dynamic

EXTRA_DIST = \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    xnoise_vala.stamp \
    Makefile.in \
    $(NULL)

