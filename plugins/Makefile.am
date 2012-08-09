NULL =

SUBDIRS =       testplugin \
                titleToDecoration \
                databaseLyrics \
                $(NULL)

DIST_SUBDIRS =  testplugin \
                titleToDecoration \
                notifications2 \
                mediakeys \
                mpris \
                mpris_one \
                chartlyrics \
                lyricwiki \
                soundmenu2 \
                databaseLyrics \
                lastfm \
                azlyrics \
                magnatune \
                ubuntuone \
                $(NULL)

if ENABLE_CHARTLYRICS
    SUBDIRS += chartlyrics
endif

if ENABLE_LASTFM
    SUBDIRS += lastfm
endif

if ENABLE_NOTIFICATIONS
    SUBDIRS += notifications2
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
    SUBDIRS += soundmenu2
endif

if ENABLE_AZLYRICS
    SUBDIRS += azlyrics
endif

if ENABLE_UBUNTUONE_MUSICSTORE
    SUBDIRS += ubuntuone
endif

if ENABLE_MAGNATUNE_MUSICSTORE
    SUBDIRS += magnatune
endif

DISTCLEANFILES = \
    Makefile.in \
    $(NULL)


