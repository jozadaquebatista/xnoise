NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

@INTLTOOL_XML_RULE@
@INTLTOOL_DESKTOP_RULE@

# Dbus service file
servicedir = $(datadir)/dbus-1/services
service_in_files = \
    org.gtk.xnoise.ImageExtractor.service.in \
    $(NULL)

service_DATA = $(service_in_files:.service.in=.service)

# Rule to make the service file with bindir expanded
$(service_DATA): $(service_in_files) Makefile
	@sed -e "s|\@bindir\@|$(bindir)|" $< > $@



bin_PROGRAMS = xnoise_image_extractor_service

INCLUDES = \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
    $(XNOISE_CFLAGS) \
    -DXN_LOCALE_DIR=\"${datarootdir}/locale\" \
    $(NULL)

xnoise_image_extractor_service_SOURCES = \
    xnoise-image-extractor-service.vala \
    $(NULL)

VALAFLAGS = \
    --basedir $(top_srcdir)/utils \
    --thread \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg xnoise-1.0 \
    --vapidir $(top_srcdir)/vapi \
    -g \
    --save-temps \
    @XNOISE_PACKAGES@ \
    $(NULL)

xnoise_image_extractor_service_LDADD = \
    $(XNOISE_LIBS) \
    -lgstpbutils-1.0 \
    -lm \
    $(top_builddir)/libxnoise/libxnoise.la \
    $(NULL)

xnoise_image_extractor_service_LDFLAGS = -export-dynamic

EXTRA_DIST = \
    $(service_in_files) \
    $(NULL)

CLEANFILES = \
    org.gtk.xnoise.ImageExtractor.service \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    *.stamp \
    Makefile.in \
    $(NULL)

