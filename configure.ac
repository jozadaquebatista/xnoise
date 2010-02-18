AC_PREREQ(2.53)
m4_define(xnoise_major_version, 0)
m4_define(xnoise_minor_version, 1)
m4_define(xnoise_micro_version, 2)
m4_define(xnoise_version, xnoise_major_version.xnoise_minor_version.xnoise_micro_version)

AC_INIT(xnoise, xnoise_version, shuerhaakenATgo oglemail.com, [xnoise])

# require automake-1.11 for vala support
AM_INIT_AUTOMAKE([1.11 no-dist-gzip dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_MAINTAINER_MODE

# Disable generation of static libraries
AC_DISABLE_STATIC

AC_PROG_CC
AM_PROG_VALAC([0.7.0])
AC_STDC_HEADERS
AC_PROG_LIBTOOL
AC_FUNC_MMAP

dnl required versions for xnoise
VALA_REQUIRED=0.7.10
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

PKG_CHECK_MODULES(XNOISE, \
    glib-2.0 >= $GLIB_REQUIRED \
    gobject-2.0 >= $GLIB_REQUIRED \
    gtk+-2.0 >= $GTK_REQUIRED \
    taglib_c >= $TAGLIB_C_REQUIRED \
    sqlite3 >= $SQLITE_REQUIRED \
    gstreamer-0.10 >= $GSTREAMER_REQUIRED \
    gstreamer-interfaces-0.10 \
    gstreamer-plugins-base-0.10 \
    gdk-2.0 \
    gdk-pixbuf-2.0 \
    gdk-x11-2.0 \
    gio-2.0 >= $GIO_REQUIRED \
    unique-1.0 \
    gmodule-2.0)

XNOISE_PACKAGES="\
    --pkg config \
    --pkg gtk+-2.0 \
    --pkg gdk-2.0 \
    --pkg gdk-x11-2.0 \
    --pkg gdk-pixbuf-2.0 \
    --pkg posix \
    --pkg sqlite3 \
    --pkg gio-2.0 \
    --pkg gstreamer-0.10 \
    --pkg gstreamer-interfaces-0.10 \
    --pkg taglib_c \
    --pkg unique-1.0 \
    --pkg gmodule-2.0 \
"

AC_SUBST(XNOISE_CFLAGS)
AC_SUBST(XNOISE_LIBS)
AC_SUBST(XNOISE_PACKAGES)


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
    AS_HELP_STRING([--enable-mediawatcher],
    [Disable mediawatcher plugin (default: disabled)]),
    [enable_mediawatcher=$enableval],
    [enable_mediawatcher=no])

if test "x$enable_mediawatcher" = "xyes"; then
        enable_mediawatcher=yes		
else
        enable_mediawatcher=no
        AC_MSG_WARN([mediawatcher plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_MEDIAWATCHER, test x"$enable_mediawatcher" = "xyes")
dnl ================================================================


# Gettext
GETTEXT_PACKAGE=xnoise
AH_TEMPLATE([GETTEXT_PACKAGE], [xnoise])
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

if test "x${prefix}" = "xNONE"; then
  PREFIX="${ac_default_prefix}"
else
  PREFIX="${prefix}"
fi
AC_DEFINE_UNQUOTED(LOCALE_DIR, "${PREFIX}/${DATADIRNAME}/locale",[Locale directory])

AC_SUBST(VALAFLAGS)

dnl Shave the output
AM_SILENT_RULES([yes])

AC_CONFIG_FILES([
    Makefile
    data/Makefile
    data/misc/xnoise.desktop.in
    data/misc/Makefile
    data/misc/xnoise-1.0.pc
    data/ui/Makefile
    src/Makefile
    src/xnoise/Makefile
    src/plugins/Makefile
    src/plugins/testplugin/Makefile
    src/plugins/titleToDecoration/Makefile
    src/plugins/lastfmCovers/Makefile
    src/plugins/leoslyrics/Makefile
    src/plugins/lyricsfly/Makefile
    src/plugins/notifications/Makefile
    src/plugins/mediawatcher/Makefile
    po/Makefile.in
])

AC_OUTPUT

echo "
  Configuration Info:
    gettext_package:               ${GETTEXT_PACKAGE}
    prefix:                        ${prefix}
    vapidir:                       ${VAPIDIR}
    CFLAGS:                        ${CFLAGS}
    
  Plugins: 
    titleToDecoration:             yes
    leoslyrics:                    ${enable_leoslyrics}
    lyricsfly:                     ${enable_lyricsfly}
    lastfm covers:                 ${enable_lastfmcovers}
    notifications:                 ${enable_notifications}
    mediwatcher:                   ${enable_mediawatcher}

"
