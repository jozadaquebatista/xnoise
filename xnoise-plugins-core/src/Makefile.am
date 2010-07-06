SUBDIRS = testplugin titleToDecoration

DIST_SUBDIRS = testplugin titleToDecoration leoslyrics lastfmCovers notifications lyricsfly mediawatcher

if ENABLE_CHARTLYRICS
  SUBDIRS += chartlyrics
endif

if ENABLE_LEOSLYRICS
  SUBDIRS += leoslyrics
endif

if ENABLE_LASTFMCOVERS
  SUBDIRS += lastfmCovers
endif

if ENABLE_NOTIFICATIONS
  SUBDIRS += notifications
endif

if ENABLE_LYRICSFLY
  SUBDIRS += lyricsfly
endif

if ENABLE_MEDIAWATCHER
  SUBDIRS += mediawatcher
endif

if ENABLE_MPRIS
  SUBDIRS += mpris
endif

if ENABLE_MEDIAKEYS
  SUBDIRS += mediakeys
endif

DISTCLEANFILES = \
	Makefile.in \
	$(NULL)
	
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)

