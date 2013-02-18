NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

bin_PROGRAMS = xnoise

INCLUDES = \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
    $(XNOISE_CFLAGS) \
    -DXN_LOCALE_DIR=\"${datarootdir}/locale\" \
    -I$(top_srcdir)/bindings/c \
    $(NULL)

xnoise_SOURCES = \
    xnoise.vala \
    $(NULL)

VALAFLAGS = \
    --basedir $(top_srcdir)/src \
    --thread \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg xnoise-1.0 \
    --vapidir $(top_srcdir)/bindings/vala \
    --pkg taginfo_c \
    --vapidir $(top_srcdir)/vapi \
    -g \
    --save-temps \
    @XNOISE_PACKAGES@ \
    $(NULL)

xnoise_LDADD = \
    $(XNOISE_LIBS) \
    -lgstpbutils-1.0 \
    -lm \
    $(top_builddir)/libxnoise/libxnoise.la \
    $(top_builddir)/bindings/c/libtaginfo_c.la \
    $(NULL)

xnoise_LDFLAGS = -export-dynamic

EXTRA_DIST = \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    xnoise_vala.stamp \
    Makefile.in \
    $(NULL)

