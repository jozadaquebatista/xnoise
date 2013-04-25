AC_PREREQ([2.68])

#xnoise version
m4_define(xnoise_major_version, 0)
m4_define(xnoise_minor_version, 2)
m4_define(xnoise_micro_version, 18)
m4_define(xnoise_version, xnoise_major_version.xnoise_minor_version.xnoise_micro_version)
m4_define([xnoise_name], [xnoise])

XNOISE_MAJOR_VERSION=xnoise_major_version
XNOISE_MINOR_VERSION=xnoise_minor_version
XNOISE_MICRO_VERSION=xnoise_micro_version
XNOISE_VERSION=xnoise_version
AC_SUBST(XNOISE_MAJOR_VERSION)
AC_SUBST(XNOISE_MINOR_VERSION)
AC_SUBST(XNOISE_MICRO_VERSION)
AC_SUBST(XNOISE_VERSION)

AC_INIT([xnoise],[xnoise_version],[shuerhaakenATgo oglemail.com],[xnoise])

AM_INIT_AUTOMAKE([1.11 dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_MAINTAINER_MODE([enable])

AC_PROG_CXX
AM_PROG_CC_C_O

# Disable generation of static libraries
AC_DISABLE_STATIC

# Vala generated C source targets GLIB Version
TARGET_GLIB_VERSION=2.34

dnl required versions for xnoise
GLIB_REQUIRED=TARGET_GLIB_VERSION
GIO_REQUIRED=GLIB_REQUIRED
GSTREAMER_REQUIRED=1.0.1
LIBXML_REQUIRED=2.6.32
GTK_REQUIRED=3.2.0
SQLITE_REQUIRED=3.6
TAGINFO_REQUIRED=0.1.6

dnl required versions for plugins
LIBXML_REQUIRED=2.6.32
LIBSOUP_REQUIRED=2.26.0
LIBAPPINDICATOR_REQUIRED=0.26


VALA_REQUIRED=0.19.0


#AC_PROG_CC
AC_HEADER_STDC
AC_FUNC_MMAP

dnl Replacement for AM_PROG_VALAC ===========
AC_PATH_PROG([VALAC], [valac], [])
 AS_IF([test -z "$VALAC"],
   [AC_MSG_WARN([No Vala compiler found. Build uses C files only. While this is fine, you will not be able to compile changed .vala source files.])],
   [AS_IF([test -n "$VALA_REQUIRED"],
      [AC_MSG_CHECKING([$VALAC is at least version $VALA_REQUIRED])
       am__vala_version=`$VALAC --version | sed 's/Vala  *//'`
       AS_VERSION_COMPARE([$VALA_REQUIRED], ["$am__vala_version"],
         [AC_MSG_RESULT([yes])],
         [AC_MSG_RESULT([yes])],
         [AC_MSG_RESULT([no])
          AC_MSG_WARN([Vala $VALA_REQUIRED not found. Your vala version is too old! Build uses C files only. While this is fine, you will not be able to compile changed .vala source files.])
          VALAC=""])])])
AM_CONDITIONAL(USE_VALA, [test -n "$VALAC"])
AC_SUBST(USE_VALA)
dnl ================================================================
dnl ================================================================

LT_INIT

dnl ================================================================


PKG_CHECK_MODULES(XNOISE, \
    gdk-3.0 \
    gdk-x11-3.0 \
    glib-2.0 >= $GLIB_REQUIRED \
    gmodule-2.0 \
    gobject-2.0 >= $GLIB_REQUIRED \
    gio-2.0 >= $GIO_REQUIRED \
    gstreamer-1.0 >= $GSTREAMER_REQUIRED \
    gstreamer-video-1.0 >= $GSTREAMER_REQUIRED \
    gstreamer-plugins-base-1.0 >= $GSTREAMER_REQUIRED \
    gtk+-3.0 >= $GTK_REQUIRED \
    sqlite3 >= $SQLITE_REQUIRED \
    libtaginfo_c >= $TAGINFO_REQUIRED \
    cairo)


dnl ================================================================
dnl plugin check for plugins dependent on libxml-2.0

PKG_CHECK_MODULES(LIBXML, \
                  libxml-2.0 >= $LIBXML_REQUIRED, \
                  have_libxml=yes, \
                  have_libxml=no)
if test "x$have_libxml" = "xno"; then
    AC_MSG_NOTICE([libxml $LIBXML_REQUIRED or greater not found.])
fi
AC_SUBST(LIBXML_CFLAGS)
AC_SUBST(LIBXML_LIBS)
dnl ================================================================



dnl ================================================================
dnl plugin check for plugins dependent on appindicator3

PKG_CHECK_MODULES(APPI, \
                  appindicator3-0.1 >= $LIBAPPINDICATOR_REQUIRED, \
                  have_appi=yes, \
                  have_appi=no)
if test "x$have_appi" = "xno"; then
    AC_MSG_NOTICE([appindicator3 is not available.])
fi
AC_SUBST(APPI_CFLAGS)
AC_SUBST(APPI_LIBS)
dnl ================================================================



dnl ================================================================
dnl plugin check for plugins dependent on GDBus

PKG_CHECK_MODULES(GDBUS, \
                  glib-2.0 >= $GLIB_REQUIRED, \
                  have_gdbus=yes, \
                  have_gdbus=no)
if test "x$have_gdbus" = "xno"; then
    AC_MSG_NOTICE([gdbus is not available.])
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
    AC_MSG_NOTICE([libsoup $LIBSOUP_REQUIRED or greater not found.])
fi
AC_SUBST(LIBSOUP_CFLAGS)
AC_SUBST(LIBSOUP_LIBS)
dnl ================================================================




dnl ================================================================
dnl plugin check for plugins dependent on xlib
X11_REQUIRED=1.3
PKG_CHECK_MODULES(X11, \
                  x11 >= $X11_REQUIRED, \
                  have_xlib=yes, \
                  have_xlib=no)
if test "x$have_xlib" != "xyes"; then
    AC_MSG_NOTICE([xlib $X11_REQUIRED or greater not found.])
fi
AC_SUBST(X11_CFLAGS)
AC_SUBST(X11_LIBS)
dnl ================================================================



dnl ================================================================
dnl plugin check for plugins dependent on gdk-x11-2.0
GDKX11_REQUIRED=3.0
PKG_CHECK_MODULES(GDKX11, \
                  gdk-x11-3.0 >= $GDKX11_REQUIRED, \
                  have_gdkx11=yes, \
                  have_gdkx11=no)
if test "x$have_gdkx11" != "xyes"; then
    AC_MSG_NOTICE([gdk-x11-3.0 $GDKX11_REQUIRED or greater not found.])
fi
AC_SUBST(GDKX11_CFLAGS)
AC_SUBST(GDKX11_LIBS)
dnl ================================================================



dnl ================================================================
dnl dependency check for optional build of app indicator plugin 

AC_ARG_ENABLE([appindicator],
    AS_HELP_STRING([--disable-appindicator],
    [Disable appindicator plugin (default: enabled)]),
    [enable_appindicator=$enableval],
    [enable_appindicator=yes])

if test "x$enable_appindicator" = "xyes"; then
    if test "x$have_appi" = "xyes"; then
        enable_appindicator=yes
    else
        enable_appindicator=no
        AC_MSG_NOTICE([appindicator plugin will not be included in the build.])
    fi
else
    enable_appindicator=no
    AC_MSG_NOTICE([appindicator plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_APPINDICATOR, test x"$enable_appindicator" = "xyes")
dnl ================================================================


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
        AC_MSG_NOTICE([lyricwiki plugin will not be included in the build.])
    fi
else
    enable_lyricwiki=no
    AC_MSG_NOTICE([lyricwiki plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_LYRICWIKI, test x"$enable_lyricwiki" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of lastfmcovers plugin 

dnl ================================================================
dnl dependency check for optional build of lastfmcovers plugin 

AC_ARG_ENABLE([lastfm],
    AS_HELP_STRING([--disable-lastfm],
    [Disable lastfm plugin (default: enabled)]),
    [enable_lastfm=$enableval],
    [enable_lastfm=yes])

if test "x$enable_lastfm" = "xyes"; then
    if test "x$have_libsoup" = "xyes"; then
        enable_lastfm=yes
    else
        enable_lastfm=no
        AC_MSG_NOTICE([lastfm plugin will not be included in the build.])
    fi
else
    enable_lastfm=no
    AC_MSG_NOTICE([lastfm plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_LASTFM, test x"$enable_lastfm" = "xyes")
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
        AC_MSG_NOTICE([mpris plugins will not be included in the build.])
    fi
else
    enable_mpris=no
    AC_MSG_NOTICE([mpris plugins will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_MPRIS, test x"$enable_mpris" = "xyes")
dnl ================================================================


dnl ================================================================
dnl dependency check for optional build of soundmenu2 plugin (ubuntu maverick+1)

AC_ARG_ENABLE([soundmenu2],
    AS_HELP_STRING([--disable-soundmenu2],
    [Disable soundmenu2 plugin (default: enabled)]),
    [enable_soundmenu2=$enableval],
    [enable_soundmenu2=yes])

if test "x$enable_soundmenu2" = "xyes"; then
    enable_soundmenu2=yes
else
    enable_soundmenu2=no
    AC_MSG_NOTICE([soundmenu2 plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_SOUNDMENU, test x"$enable_soundmenu2" = "xyes")
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
            AC_MSG_NOTICE([mediakeys plugin will not be included in the build.])
        fi
    else
        enable_mediakeys=no
        AC_MSG_NOTICE([mediakeys plugin will not be included in the build.])
    fi
else
    enable_mediakeys=no
    AC_MSG_NOTICE([mediakeys plugin will not be included in the build.])
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
        AC_MSG_NOTICE([chartlyrics plugin will not be included in the build.])
    fi
else
    enable_chartlyrics=no
    AC_MSG_NOTICE([chartlyrics plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_CHARTLYRICS, test x"$enable_chartlyrics" = "xyes")
dnl ================================================================

dnl ================================================================
dnl dependency check for optional build of azlyrics plugin 

AC_ARG_ENABLE([azlyrics],
    AS_HELP_STRING([--disable-azlyrics],
    [Disable azlyrics plugin (default: enabled)]),
    [enable_azlyrics=$enableval],
    [enable_azlyrics=yes])

if test "x$enable_azlyrics" = "xyes"; then
    if test "x$have_libxml" = "xyes" && test "x$have_libsoup" = "xyes"; then
        enable_azlyrics=yes
    else
        enable_azlyrics=no
        AC_MSG_NOTICE([azlyrics plugin will not be included in the build.])
    fi
else
    enable_azlyrics=no
    AC_MSG_NOTICE([azlyrics plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_AZLYRICS, test x"$enable_azlyrics" = "xyes")
dnl ================================================================



dnl ================================================================
dnl dependency check for optional build of magnatune plugin 

AC_ARG_ENABLE([magnatune],
    AS_HELP_STRING([--disable-magnatune],
    [Disable magnatune music store plugin (default: enabled)]),
    [enable_magnatune=$enableval],
    [enable_magnatune=yes])

if test "x$enable_magnatune" = "xyes"; then
    enable_magnatune=yes
else
    enable_magnatune=no
    AC_MSG_NOTICE([magnatune music store plugin will not be included in the build.])
fi
AM_CONDITIONAL(ENABLE_MAGNATUNE_MUSICSTORE, test x"$enable_magnatune" = "xyes")
dnl ================================================================


dnl ================================================================
AC_ARG_ENABLE([reftrack],
    AS_HELP_STRING([--enable-reftrack],
    [Enable Object debug (default: disabled)]),
    [enable_reftrack=$enableval],
    [enable_reftrack=no])

if test "x$enable_reftrack" = "xyes"; then
    AC_MSG_NOTICE([Ref tracking enabled.])
else
    AC_MSG_NOTICE([Ref tracking not enabled.])
fi
AM_CONDITIONAL(REF_TRACKING_ENABLED, test x"$enable_reftrack" = "xyes")
dnl ================================================================


dnl ================================================================
dnl check for gtk version > 3.4
PKG_CHECK_MODULES(GTK_EXTRA, \
                  gtk+-3.0 >= 3.4.0, \
                  have_gtk_v34=yes, \
                  have_gtk_v34=no)
if test "x$have_gtk_v34" = "xyes"; then
    AC_MSG_NOTICE([Some extra features of Gtk >= 3.4 will be used. ])
else
    AC_MSG_NOTICE([Some extra features of Gtk >= 3.4 will not be used. ])
fi
AM_CONDITIONAL(HAVE_MIN_GTK_34, test x"$have_gtk_v34" = "xyes")
dnl ================================================================





XNOISE_PACKAGES="\
    --pkg config \
    --pkg gdk-3.0 \
    --pkg gdk-x11-3.0 \
    --pkg gio-2.0 \
    --pkg libxml-2.0 \
    --pkg gmodule-2.0 \
    --pkg gstreamer-1.0 \
    --pkg gstreamer-video-1.0 \
    --pkg gstreamer-pbutils-1.0 \
    --pkg gstreamer-base-1.0 \
    --pkg gstreamer-tag-1.0 \
    --pkg gtk+-3.0 \
    --pkg posix \
    --pkg sqlite3 \
    --pkg libtaginfo_c \
    --target-glib=`echo $TARGET_GLIB_VERSION` \
    --disable-version-header \
    --enable-checking \
"


AC_SUBST(XNOISE_CFLAGS)
AC_SUBST(XNOISE_LIBS)
AC_SUBST(XNOISE_PACKAGES)


dnl       VAPIDIR is used to place the xnoise vapi file
dnl       $XN_DATADIR/vala/vapi is vala version independent
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

AM_SILENT_RULES([yes])

AC_CONFIG_FILES([
    Makefile
    data/Makefile
    data/misc/xnoise.desktop.in
    data/misc/Makefile
    data/misc/xnoise-1.0.pc
    data/ui/Makefile
    data/icons/Makefile
    data/icons/32x32/Makefile
    data/icons/48x48/Makefile
    data/icons/256x256/Makefile
    data/icons/scalable/Makefile
    data/icons/ubuntu-mono-dark/Makefile
    data/icons/ubuntu-mono-light/Makefile
    libxnoise/Makefile
    src/Makefile
    packaging/Makefile
    plugins/Makefile
    plugins/app_indicator/Makefile
    plugins/azlyrics/Makefile
    plugins/chartlyrics/Makefile
    plugins/databaseLyrics/Makefile
    plugins/testplugin/Makefile
    plugins/titleToDecoration/Makefile
    plugins/lastfm/Makefile
    plugins/lastfm/icons/Makefile
    plugins/lastfm/icons/scalable/Makefile
    plugins/lyricwiki/Makefile
    plugins/magnatune/Makefile
    plugins/magnatune/icons/Makefile
    plugins/magnatune/icons/scalable/Makefile
    plugins/mediakeys/Makefile
    plugins/mpris/Makefile
    plugins/mpris_one/Makefile
    plugins/soundmenu2/Makefile
    po/Makefile.in
    doc/Makefile
    tests/Makefile
    utils/Makefile
    vapi/Makefile
])

AC_OUTPUT

bold=`tput bold`
normal=`tput sgr0`

echo "
  ${bold}${PACKAGE} ${VERSION}${normal}
  ~~~~~~~~~~~~~
  
  ${bold}CONFIGURATION INFO${normal}
    Prefix:                        ${prefix}
    Gettext package:               ${GETTEXT_PACKAGE}
    CFLAGS:                        ${CFLAGS}
    Vala compiler (if applicable): ${VALAC}
    Vala's glib target version:    ${TARGET_GLIB_VERSION}
    Debug references:              ${enable_reftrack}
  
  ${bold}PLUGINS included in this build${normal}
  
    ${bold}General Plugins${normal}
    Lastfm (Album images 
            and 'scrobbling')      ${enable_lastfm}
    Keyboard Media Key control     ${enable_mediakeys}
    Mpris v1/v2 dbus interfaces    ${enable_mpris}
    Test plugin (Demo Plugin)      yes (always)
    Title-To-Decoration            yes (always)
    Ubuntu soundmenu               ${enable_soundmenu2}
    AppIndicator                   ${enable_appindicator}
    
    ${bold}Music Store Plugins:${normal}
    Magnatune Music Store          ${enable_magnatune}
    
    ${bold}Lyrics Provider Plugins:${normal}
    DatabaseLyrics (Buffer)        yes (always)
    Chartlyrics                    ${enable_chartlyrics}
    Azlyrics                       ${enable_azlyrics}
    Lyricwiki                      ${enable_lyricwiki}

  Note: Single plugin builds can be deactivated
        manually by user option or automatically,
        in case the dependencies are not available.
"

