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
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
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

