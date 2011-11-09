SUBDIRS = testplugin titleToDecoration cyclic-save-state databaseLyrics

DIST_SUBDIRS = testplugin titleToDecoration cyclic-save-state lastfmCovers notifications notifications2 mediakeys mpris mpris_one chartlyrics lyricwiki soundmenu soundmenu2 databaseLyrics lastfm

if ENABLE_CHARTLYRICS
  SUBDIRS += chartlyrics
endif

#if ENABLE_LASTFMCOVERS
#  SUBDIRS += lastfmCovers
#endif

if ENABLE_LASTFM
  SUBDIRS += lastfm
endif

if ENABLE_NOTIFICATIONS
  SUBDIRS += notifications
else
if ENABLE_NOTIFICATIONS2
  SUBDIRS += notifications2
endif
endif

if ENABLE_MPRIS
  SUBDIRS += mpris
  SUBDIRS += mpris_one
endif

if ENABLE_MEDIAKEYS
  SUBDIRS += mediakeys
endif

if ENABLE_LYRICWIKI
  SUBDIRS += lyricwiki
endif

if ENABLE_SOUNDMENU
  SUBDIRS += soundmenu
else
if ENABLE_SOUNDMENU2
  SUBDIRS += soundmenu2
endif
endif


DISTCLEANFILES = \
	Makefile.in \
	$(NULL)


