NULL =

desktopdir = $(datadir)/applications
desktop_in_files = xnoise.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = xnoise-1.0.pc
plpkgconfigdir = $(libdir)/pkgconfig
plpkgconfig_DATA = libplaylist-1.0.pc

EXTRA_DIST = \
    $(desktop_in_files) \
    xnoise-1.0.pc.in \
    libplaylist-1.0.pc.in \
    $(NULL)

CLEANFILES = \
    $(desktop_DATA)

DISTCLEANFILES = \
    Makefile.in \
    $(pkgconfig_DATA) \
    $(plpkgconfig_DATA) \
    $(NULL)
	
MAINTAINERCLEANFILES = \
    Makefile.in \
    $(NULL)


