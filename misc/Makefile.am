NULL =

desktopdir 	 = $(datadir)/applications
desktop_in_files = xnoise.desktop.in
desktop_DATA 	 = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appicon_DATA = xnoise.png
appicondir = $(datadir)/icons/hicolor/48x48/apps

EXTRA_DIST = \
	$(appicon_DATA) \
	$(desktop_in_files)	\
	$(NULL)	

CLEANFILES = \
	$(desktop_DATA)	

DISTCLEANFILES = \
	Makefile.in \
	$(NULL)
	
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)

