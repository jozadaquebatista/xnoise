AC_PREREQ(2.53)
m4_define(xnoisepluginscore_major_version, 0)
m4_define(xnoisepluginscore_minor_version, 1)
m4_define(xnoisepluginscore_micro_version, 11)
m4_define(xnoisepluginscore_version, xnoisepluginscore_major_version.xnoisepluginscore_minor_version.xnoisepluginscore_micro_version)

AC_INIT(xnoisepluginscore, xnoisepluginscore_version, shuerhaakenATgo oglemail.com, [xnoise-plugins-core])

# require automake-1.11 for vala support
AM_INIT_AUTOMAKE([1.11 dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_MAINTAINER_MODE

dnl required versions for xnoise
GSTREAMER_REQUIRED=0.10.23
GLIB_REQUIRED=2.12.0
GIO_REQUIRED=2.16
GTK_REQUIRED=2.18.0
SQLITE_REQUIRED=3.4
TAGLIB_C_REQUIRED=1.5.0

dnl required versions for plugins
LIBNOTIFY_REQUIRED=0.4.5
LIBXML_REQUIRED=2.6.32
LIBSOUP_REQUIRED=2.26.0
DBUS_GLIB_REQUIRED=0.0.1
LIBINDICATE_REQUIRED=0.1
XNOISE_REQUIRED=xnoisepluginscore_version

dnl required versions for vala, if used
VALA_REQUIRED=0.9.8

# Disable generation of static libraries
AC_DISABLE_STATIC

AC_PROG_CC
AC_ARG_ENABLE([usevala],
    AS_HELP_STRING([--disable-usevala],
    [Disable use of vala for releases that are compiled on a system that has old version of vala (default: enabled)]),
    [enable_usevala=$enableval],
    [enable_usevala=yes])

if test "x$enable_usevala" = "xyes"; then
    PKG_CHECK_MODULES(VALACOMPILER, \
                      vala-0.10 >= $VALA_REQUIRED, \
                      have_vala=yes, \
                      have_vala=no)
    if test "x$have_vala" = "xno"; then
        AC_MSG_WARN([vala $VALA_REQUIRED or greater not found.])
    else
        AM_PROG_VALAC($VALA_REQUIRED)
    fi
fi

AC_STDC_HEADERS
AC_PROG_LIBTOOL
AC_FUNC_MMAP

PKG_CHECK_MODULES(XNOISEPLUGINSCORE, xnoise-1.0 = $XNOISE_REQUIRED)

XNOISEPLUGINSCORE_PACKAGES="\
    --pkg config \
    --pkg gtk+-2.0 \
    --pkg gdk-2.0 \
    --pkg gdk-pixbuf-2.0 \
    --pkg posix \
    --pkg sqlite3 \
    --pkg gio-2.0 \
    --pkg gstreamer-0.10 \
    --pkg gstreamer-pbutils-0.10 \
    --pkg gstreamer-interfaces-0.10 \
    --pkg taglib_c \
    --pkg unique-1.0 \
    --pkg gmodule-2.0 \
    --pkg xnoise-1.0 \
"

AC_SUBST(XNOISEPLUGINSCORE_CFLAGS)
AC_SUBST(XNOISEPLUGINSCORE_LIBS)
AC_SUBST(XNOISEPLUGINSCORE_PACKAGES)


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
dnl plugin check for plugins dependent on dbus-glib

PKG_CHECK_MODULES(LIBDBUS_GLIB, \
                  dbus-glib-1 >= $DBUS_GLIB_REQUIRED, \
                  have_dbus_glib=yes, \
                  have_dbus_glib=no)
if test "x$have_dbus_glib" != "xyes"; then
    AC_MSG_WARN([dbus-glib $DBUS_GLIB_REQUIRED or greater not found.])
fi
AC_SUBST(LIBDBUS_GLIB_CFLAGS)
AC_SUBST(LIBDBUS_GLIB_LIBS)
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
    if test "x$have_dbus_glib" = "xyes"; then
        if test "x$have_libindicate" = "xyes"; then
            enable_mpris=yes
        else
            enable_mpris=no
            AC_MSG_WARN([mpris plugin will not be included in the build.])
        fi
    else
        enable_mpris=no
        AC_MSG_WARN([mpris plugin will not be included in the build.])
    fi
fi
AM_CONDITIONAL(ENABLE_MPRIS, test x"$enable_mpris" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of mediakeys plugin 

AC_ARG_ENABLE([mediakeys],
    AS_HELP_STRING([--disable-mediakeys],
    [Disable mediakeys plugin (default: enabled)]),
    [enable_mediakeys=$enableval],
    [enable_mediakeys=yes])

if test "x$enable_mediakeys" = "xyes"; then
    if test "x$have_dbus_glib" = "xyes"; then
        enable_mediakeys=yes
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


# Gettext
GETTEXT_PACKAGE=xnoise-plugins-core
AH_TEMPLATE([GETTEXT_PACKAGE], [xnoise-plugins-core])
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

AC_SUBST(VALAFLAGS)

dnl Shave the output
AM_SILENT_RULES([yes])

AC_CONFIG_FILES([
    Makefile
    data/Makefile
    data/misc/Makefile
    data/misc/xnoise-plugins-core-1.0.pc
    src/Makefile
    src/testplugin/Makefile
    src/titleToDecoration/Makefile
    src/lastfmCovers/Makefile
    src/leoslyrics/Makefile
    src/lyricsfly/Makefile
    src/notifications/Makefile
    src/mediawatcher/Makefile
    src/mpris/Makefile
    src/mediakeys/Makefile
    src/chartlyrics/Makefile
    src/lyricwiki/Makefile
    po/Makefile.in
    vapi/Makefile
])

AC_OUTPUT

echo "
  ${PACKAGE} ${VERSION}
  ~~~~~~~~~~~~~~~~~~~~~~~~~
  
  Configuration Info:
    gettext_package:               ${GETTEXT_PACKAGE}
    prefix:                        ${prefix}
    CFLAGS:                        ${CFLAGS}
    
  Plugins included in this build: 
    titleToDecoration:             yes (always)
    leoslyrics:                    ${enable_leoslyrics}
    lyricsfly:                     ${enable_lyricsfly}
    chartlyrics:                   ${enable_chartlyrics}
    lyricwiki:                     ${enable_lyricwiki}
    lastfm covers:                 ${enable_lastfmcovers}
    notifications:                 ${enable_notifications}
    mediawatcher:                  ${enable_mediawatcher}
    mpris:                         ${enable_mpris}
    mediakeys:                     ${enable_mediakeys}
"
