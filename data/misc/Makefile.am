NULL =

desktopdir 	 = $(datadir)/applications
desktop_in_files = xnoise.desktop.in
desktop_DATA 	 = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = xnoise-1.0.pc

appicon_DATA = xnoise.png
appicondir = $(datadir)/icons/hicolor/48x48/apps

appiconscalable_DATA = xnoise.svg
appiconscalabledir = $(datadir)/icons/hicolor/scalable/apps

EXTRA_DIST = \
	$(appicon_DATA) \
	$(appiconscalable_DATA) \
	$(desktop_in_files)	\
	xnoise-1.0.pc.in \
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

