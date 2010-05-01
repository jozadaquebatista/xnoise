NULL =

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = xnoise-plugins-core-1.0.pc

appicon_DATA = xnoise.png
appicondir = $(datadir)/icons/hicolor/48x48/apps

appiconscalable_DATA = xnoise.svg
appiconscalabledir = $(datadir)/icons/hicolor/scalable/apps

EXTRA_DIST = \
	$(desktop_in_files) \
	$(appicon_DATA) \
	$(appiconscalable_DATA) \
	xnoise-plugins-core-1.0.pc.in \
	$(NULL)

CLEANFILES = \
	$(desktop_DATA)

DISTCLEANFILES = \
	Makefile.in \
	$(pkgconfig_DATA) \
	$(NULL)
	
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)

