DIST_SUBDIRS = testplugin titleToDecoration leoslyrics lastfmCovers notifications

SUBDIRS = testplugin titleToDecoration

if ENABLE_LEOSLYRICS
  SUBDIRS += leoslyrics
endif

if ENABLE_LASTFMCOVERS
  SUBDIRS += lastfmCovers
endif

if ENABLE_NOTIFICATIONS
  SUBDIRS += notifications
endif

DISTCLEANFILES = \
	Makefile.in \
	$(NULL)
	
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)


