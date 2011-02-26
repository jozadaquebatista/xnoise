AC_PREREQ([2.67])

#xnoise version
m4_define(xnoise_major_version, 0)
m4_define(xnoise_minor_version, 1)
m4_define(xnoise_micro_version, 16)
m4_define(xnoise_version, xnoise_major_version.xnoise_minor_version.xnoise_micro_version)

#libplaylist version
m4_define(libplaylist_major_version, 0)
m4_define(libplaylist_minor_version, 0)
m4_define(libplaylist_micro_version, 1)
m4_define(libplaylist_version, libplaylist_major_version.libplaylist_minor_version.libplaylist_micro_version)

AC_INIT([xnoise],[xnoise_version],[shuerhaakenATgo oglemail.com],[xnoise])

# require automake-1.11 for vala support
AM_INIT_AUTOMAKE([1.11 dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_MAINTAINER_MODE

# Disable generation of static libraries
AC_DISABLE_STATIC

dnl required versions for xnoise
GSTREAMER_REQUIRED=0.10.23
GLIB_REQUIRED=2.12.0
LIBXML_REQUIRED=2.6.32
GIO_REQUIRED=2.16
GTK_REQUIRED=2.18.0
SQLITE_REQUIRED=3.4
TAGLIB_C_REQUIRED=1.5.0

dnl required versions for plugins
LIBNOTIFY_REQUIRED=0.4.5
LIBXML_REQUIRED=2.6.32
LIBSOUP_REQUIRED=2.26.0
DBUS_GLIB_REQUIRED=0.0.1
LIBINDICATE_REQUIRED=0.4.2
GDBUS_REQUIRED=2.26

dnl required versions for vala, if used
VALA_REQUIRED=0.11.5

AC_PROG_CC
AM_PROG_VALAC($VALA_REQUIRED)

AC_HEADER_STDC
LT_INIT
AC_FUNC_MMAP

PKG_CHECK_MODULES(XNOISE, \
    gdk-2.0 \
    gdk-pixbuf-2.0 \
    gdk-x11-2.0 \
    glib-2.0 >= $GLIB_REQUIRED \
    gmodule-2.0 \
    gobject-2.0 >= $GLIB_REQUIRED \
    gio-2.0 >= $GIO_REQUIRED \
    gstreamer-0.10 >= $GSTREAMER_REQUIRED \
    gstreamer-interfaces-0.10 \
    gstreamer-plugins-base-0.10 \
    gtk+-2.0 >= $GTK_REQUIRED \
    sqlite3 >= $SQLITE_REQUIRED \
    taglib_c >= $TAGLIB_C_REQUIRED \
    unique-1.0 cairo)

PKG_CHECK_MODULES(LIBPLAYLIST, \
    glib-2.0 >= $GLIB_REQUIRED \
    gobject-2.0 >= $GLIB_REQUIRED \
    libxml-2.0 >= $LIBXML_REQUIRED \
    gio-2.0 >= $GIO_REQUIRED)


dnl ================================================================
dnl plugin check for plugins dependent on libxml-2.0

PKG_CHECK_MODULES(LIBXML, \
                  libxml-2.0 >= $LIBXML_REQUIRED, \
                  have_libxml=yes, \
                  have_libxml=no)
if test "x$have_libxml" = "xno"; then
    AC_MSG_WARN([libxml $LIBXML_REQUIRED or greater not found.])
fi
AC_SUBST(LIBXML_CFLAGS)
AC_SUBST(LIBXML_LIBS)
dnl ================================================================


dnl ================================================================
dnl plugin check for plugins dependent on GDBus

PKG_CHECK_MODULES(GDBUS, \
                  glib-2.0 >= $GDBUS_REQUIRED, \
                  have_gdbus=yes, \
                  have_gdbus=no)
if test "x$have_gdbus" = "xno"; then
    AC_MSG_WARN([gdbus is not available.])
fi
AC_SUBST(GDBUS_CFLAGS)
AC_SUBST(GDBUS_LIBS)
dnl ================================================================



dnl ================================================================
dnl plugin check for plugins dependent on libsoup-2.4

PKG_CHECK_MODULES(LIBSOUP, \
                  libsoup-2.4 >= $LIBSOUP_REQUIRED, \
                  have_libsoup=yes, \
                  have_libsoup=no)
if test "x$have_libsoup" != "xyes"; then
    AC_MSG_WARN([libsoup $LIBSOUP_REQUIRED or greater not found.])
fi
AC_SUBST(LIBSOUP_CFLAGS)
AC_SUBST(LIBSOUP_LIBS)
dnl ================================================================




dnl ================================================================
dnl plugin check for plugins dependent on libnotify

PKG_CHECK_MODULES(LIBNOTIFY, \
                  libnotify >= $LIBNOTIFY_REQUIRED, \
                  have_libnotify=yes, \
                  have_libnotify=no)
if test "x$have_libnotify" != "xyes"; then
    AC_MSG_WARN([libnotify $LIBNOTIFY_REQUIRED or greater not found.])
fi
AC_SUBST(LIBNOTIFY_CFLAGS)
AC_SUBST(LIBNOTIFY_LIBS)
dnl ================================================================



dnl ================================================================
dnl plugin check for plugins dependent on libindicate

PKG_CHECK_MODULES(LIBINDICATE, \
                  indicate >= $LIBINDICATE_REQUIRED, \
                  have_libindicate=yes, \
                  have_libindicate=no)
if test "x$have_libindicate" != "xyes"; then
    AC_MSG_WARN([libindicate $LIBINDICATE_REQUIRED or greater not found.])
fi
AC_SUBST(LIBINDICATE_CFLAGS)
AC_SUBST(LIBINDICATE_LIBS)
dnl ================================================================



dnl ================================================================
dnl plugin check for plugins dependent on xlib
X11_REQUIRED=1.3
PKG_CHECK_MODULES(X11, \
                  x11 >= $X11_REQUIRED, \
                  have_xlib=yes, \
                  have_xlib=no)
if test "x$have_xlib" != "xyes"; then
    AC_MSG_WARN([xlib $X11_REQUIRED or greater not found.])
fi
AC_SUBST(X11_CFLAGS)
AC_SUBST(X11_LIBS)
dnl ================================================================



dnl ================================================================
dnl plugin check for plugins dependent on gdk-x11-2.0
GDKX11_REQUIRED=2.0
PKG_CHECK_MODULES(GDKX11, \
                  gdk-x11-2.0 >= $GDKX11_REQUIRED, \
                  have_gdkx11=yes, \
                  have_gdkx11=no)
if test "x$have_gdkx11" != "xyes"; then
    AC_MSG_WARN([gdk-x11-2.0 $GDKX11_REQUIRED or greater not found.])
fi
AC_SUBST(GDKX11_CFLAGS)
AC_SUBST(GDKX11_LIBS)
dnl ================================================================



dnl ================================================================
dnl dependency check for optional build of leoslyrics plugin 

AC_ARG_ENABLE([leoslyrics],
    AS_HELP_STRING([--disable-leoslyrics],
    [Disable lyric plugin (default: enabled)]),
    [enable_leoslyrics=$enableval],
    [enable_leoslyrics=yes])

if test "x$enable_leoslyrics" = "xyes"; then
    if test "x$have_libxml" = "xyes" && test "x$have_libsoup" = "xyes"; then
        enable_leoslyrics=yes
    else
        enable_leoslyrics=no
        AC_MSG_WARN([leoslyrics plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_LEOSLYRICS, test x"$enable_leoslyrics" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of lyricsfly plugin 

AC_ARG_ENABLE([lyricsfly],
    AS_HELP_STRING([--disable-lyricsfly],
    [Disable lyric plugin (default: enabled)]),
    [enable_lyricsfly=$enableval],
    [enable_lyricsfly=yes])

if test "x$enable_lyricsfly" = "xyes"; then
    if test "x$have_libxml" = "xyes" && test "x$have_libsoup" = "xyes"; then
        enable_lyricsfly=yes
    else
        enable_lyricsfly=no
        AC_MSG_WARN([lyricsfly plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_LYRICSFLY, test x"$enable_lyricsfly" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of lyricwiki plugin 

AC_ARG_ENABLE([lyricwiki],
    AS_HELP_STRING([--disable-lyricwiki],
    [Disable lyricwiki plugin (default: enabled)]),
    [enable_lyricwiki=$enableval],
    [enable_lyricwiki=yes])

if test "x$enable_lyricwiki" = "xyes"; then
    if test "x$have_libxml" = "xyes" && test "x$have_libsoup" = "xyes"; then
        enable_lyricwiki=yes
    else
        enable_lyricwiki=no
        AC_MSG_WARN([lyricwiki plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_LYRICWIKI, test x"$enable_lyricwiki" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of lastfmcovers plugin 

AC_ARG_ENABLE([lastfm-covers],
    AS_HELP_STRING([--disable-lastfm-covers],
    [Disable lastfm covers plugin (default: enabled)]),
    [enable_lastfmcovers=$enableval],
    [enable_lastfmcovers=yes])

if test "x$enable_lastfmcovers" = "xyes"; then
    if test "x$have_libxml" = "xyes" && test "x$have_libsoup" = "xyes"; then
        enable_lastfmcovers=yes
    else
        enable_lastfmcovers=no
        AC_MSG_WARN([lastfmcovers plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_LASTFMCOVERS, test x"$enable_lastfmcovers" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of notifications plugin 

AC_ARG_ENABLE([notifications],
    AS_HELP_STRING([--disable-notifications],
    [Disable notifications plugin (default: enabled)]),
    [enable_notifications=$enableval],
    [enable_notifications=yes])

if test "x$enable_notifications" = "xyes"; then
    if test "x$have_libnotify" = "xyes"; then
        enable_notifications=yes
    else
        enable_notifications=no
        AC_MSG_WARN([notifications plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_NOTIFICATIONS, test x"$enable_notifications" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of mediawatcher plugin 

AC_ARG_ENABLE([mediawatcher],
    AS_HELP_STRING([--disable-mediawatcher],
    [Disable mediawatcher plugin (default: enabled)]),
    [enable_mediawatcher=$enableval],
    [enable_mediawatcher=yes])

if test "x$enable_mediawatcher" = "xyes"; then
	enable_mediawatcher=yes
else
   	enable_mediawatcher=no
   	AC_MSG_WARN([mediawatcher plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_MEDIAWATCHER, test x"$enable_mediawatcher" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of mpris plugin 

AC_ARG_ENABLE([mpris],
    AS_HELP_STRING([--disable-mpris],
    [Disable mpris plugin (default: enabled)]),
    [enable_mpris=$enableval],
    [enable_mpris=yes])

if test "x$enable_mpris" = "xyes"; then
    if test "x$have_gdbus" = "xyes"; then
        enable_mpris=yes
    else
        enable_mpris=no
        AC_MSG_WARN([mpris plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_MPRIS, test x"$enable_mpris" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of soundmenu plugin 

AC_ARG_ENABLE([soundmenu],
    AS_HELP_STRING([--disable-soundmenu],
    [Disable soundmenu plugin (default: enabled)]),
    [enable_soundmenu=$enableval],
    [enable_soundmenu=yes])

if test "x$enable_soundmenu" = "xyes"; then
    if test "x$have_libindicate" = "xyes"; then
        if test "x$enable_mpris" = "xyes"; then
            enable_soundmenu=yes
        else
            enable_soundmenu=no
            AC_MSG_WARN([soundmenu plugin will not be included in the build.])
        fi
    else
        enable_soundmenu=no
        AC_MSG_WARN([soundmenu plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_SOUNDMENU, test x"$enable_soundmenu" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of soundmenu2 plugin (ubuntu maverick+1)

AC_ARG_ENABLE([soundmenu2],
    AS_HELP_STRING([--disable-soundmenu2],
    [Disable soundmenu2 plugin (default: enabled)]),
    [enable_soundmenu2=$enableval],
    [enable_soundmenu2=yes])

if test "x$enable_soundmenu2" = "xyes"; then
    if test "x$enable_soundmenu" = "xno"; then
        if test "x$enable_mpris" = "xyes"; then
            enable_soundmenu2=yes
        else
            enable_soundmenu2=no
            AC_MSG_WARN([soundmenu2 plugin will not be included in the build.])
        fi
    else
        enable_soundmenu2=no
        AC_MSG_WARN([soundmenu2 plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_SOUNDMENU2, test x"$enable_soundmenu2" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of mediakeys plugin 

AC_ARG_ENABLE([mediakeys],
    AS_HELP_STRING([--disable-mediakeys],
    [Disable mediakeys plugin (default: enabled)]),
    [enable_mediakeys=$enableval],
    [enable_mediakeys=yes])

if test "x$enable_mediakeys" = "xyes"; then
    if test "x$have_gdkx11" = "xyes"; then
        if test "x$have_xlib" = "xyes"; then
            enable_mediakeys=yes
        else
            enable_mediakeys=no
            AC_MSG_WARN([mediakeys plugin will not be included in the build.])
        fi
    else
        enable_mediakeys=no
        AC_MSG_WARN([mediakeys plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_MEDIAKEYS, test x"$enable_mediakeys" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of chartlyrics plugin 

AC_ARG_ENABLE([chartlyrics],
    AS_HELP_STRING([--disable-chartlyrics],
    [Disable chartlyrics plugin (default: enabled)]),
    [enable_chartlyrics=$enableval],
    [enable_chartlyrics=yes])

if test "x$enable_chartlyrics" = "xyes"; then
    if test "x$have_libxml" = "xyes" && test "x$have_libsoup" = "xyes"; then
        enable_chartlyrics=yes
    else
        enable_chartlyrics=no
        AC_MSG_WARN([chartlyrics plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_CHARTLYRICS, test x"$enable_chartlyrics" = "xyes")
dnl ================================================================



XNOISE_PACKAGES="\
    --pkg config \
    --pkg gdk-2.0 \
    --pkg gdk-pixbuf-2.0 \
    --pkg gdk-x11-2.0 \
    --pkg gio-2.0 \
    --pkg libxml-2.0 \
    --pkg gmodule-2.0 \
    --pkg gstreamer-0.10 \
    --pkg gstreamer-pbutils-0.10 \
    --pkg gstreamer-interfaces-0.10 \
    --pkg gtk+-2.0 \
    --pkg posix \
    --pkg sqlite3 \
    --pkg taglib_c \
    --pkg unique-1.0 \
    --pkg linux \
"

LIBPLAYLIST_PACKAGES="\
    --pkg config \
"

AC_SUBST(XNOISE_CFLAGS)
AC_SUBST(XNOISE_LIBS)
AC_SUBST(XNOISE_PACKAGES)

AC_SUBST(LIBPLAYLIST_CFLAGS)
AC_SUBST(LIBPLAYLIST_LIBS)
AC_SUBST(LIBPLAYLIST_PACKAGES)


dnl       VAPIDIR is used to place the xnoise vapi file
dnl       $DATADIR/vala/vapi is vala version independent
VAPIDIR="${datadir}/vala/vapi"
AC_SUBST(VAPIDIR)
dnl ================================================================

# Gettext
GETTEXT_PACKAGE=xnoise
AH_TEMPLATE([GETTEXT_PACKAGE], [xnoise])
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"])
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT

IT_PROG_INTLTOOL([0.35.0])

dnl Shave the output
AM_SILENT_RULES([yes])

AC_CONFIG_FILES([
    Makefile
    data/Makefile
    data/misc/xnoise.desktop.in
    data/misc/Makefile
    data/misc/xnoise-1.0.pc
    data/misc/libplaylist-1.0.pc
    data/ui/Makefile
    data/icons/Makefile
    data/icons/32x32/Makefile
    data/icons/48x48/Makefile
    data/icons/256x256/Makefile
    data/icons/scalable/Makefile
    libplaylist/Makefile
    src/Makefile
    plugins/Makefile
    plugins/testplugin/Makefile
    plugins/titleToDecoration/Makefile
    plugins/cyclic-save-state/Makefile
    plugins/lastfmCovers/Makefile
    plugins/leoslyrics/Makefile
    plugins/lyricsfly/Makefile
    plugins/notifications/Makefile
    plugins/mediawatcher/Makefile
    plugins/mpris/Makefile
    plugins/mediakeys/Makefile
    plugins/chartlyrics/Makefile
    plugins/lyricwiki/Makefile
    plugins/soundmenu/Makefile
    plugins/soundmenu2/Makefile
    po/Makefile.in
    vapi/Makefile
    tests/Makefile
])

AC_OUTPUT

echo "
  ${PACKAGE} ${VERSION}
  ~~~~~~~~~~~~
  
  Configuration Info:
    gettext_package:               ${GETTEXT_PACKAGE}
    prefix:                        ${prefix}
    CFLAGS:                        ${CFLAGS}
    VALAC                          ${VALAC}

  Plugins included in this build: 
    titleToDecoration:             yes (always build)
    cyclic-save-state:             yes (always build)
    leoslyrics:                    ${enable_leoslyrics}
    lyricsfly:                     ${enable_lyricsfly}
    chartlyrics:                   ${enable_chartlyrics}
    lyricwiki:                     ${enable_lyricwiki}
    lastfm covers:                 ${enable_lastfmcovers}
    notifications:                 ${enable_notifications}
    mediawatcher:                  ${enable_mediawatcher}
    mpris:                         ${enable_mpris}
    mediakeys:                     ${enable_mediakeys}
    soundmenu:                     ${enable_soundmenu}
    soundmenu2:                    ${enable_soundmenu2}
"
