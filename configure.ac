AC_INIT(xnoise, 0.1.0, shuerhaak en(at)SPAMFREE g o ogl ema il (dot)com, [xnoise])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)


dnl ================================================================
dnl gettext for xnoise
dnl ================================================================

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

VAPIDIR=`pkg-config --variable=vapidir vala-1.0`

AC_SUBST(VAPIDIR)
AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)



dnl ================================================================
dnl checks for xnoise
dnl ================================================================

GLIB_REQUIRED=2.12.0
GTK_REQUIRED=2.16.0
SQLITE_REQUIRED=3.4

PKG_CHECK_MODULES(XNOISE, glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gtk+-2.0 >= $GTK_REQUIRED taglib_c sqlite3 >= $SQLITE_REQUIRED gstreamer-0.10 gstreamer-interfaces-0.10 gstreamer-plugins-base-0.10 gdk-2.0 gdk-pixbuf-2.0 gdk-x11-2.0 gio-2.0 unique-1.0 gmodule-2.0)




dnl ================================================================
dnl plugins checks for plugins dependent on libxml-2.0
dnl ================================================================

LIBXML_REQUIRED=2.0.0
	
AC_ARG_ENABLE([lyrics],
	AS_HELP_STRING([--disable-lyrics],[Disable lyric plugin (default: enabled)]),
	[enable_lyrics=$enableval],
	[enable_lyrics=yes])

if test "x$enable_lyrics" = "xyes"; then
	PKG_CHECK_MODULES(LIBXML, \
                      libxml-2.0 >= $LIBXML_REQUIRED, \
	                  have_libxml=yes, \
                      have_libxml=no)
	if test "x$have_libxml" = "xyes"; then
		enable_lyrics=yes		
	else
        AC_MSG_WARN([libxml $LIBXML_REQUIRED or greater not found.])

		enable_lyrics=no
        AC_MSG_WARN([lyrics plugin will not be included in the build.])
	fi
fi

AM_CONDITIONAL(ENABLE_LYRICS, test x"$enable_lyrics" = "xyes")





AC_SUBST(XNOISE_CFLAGS)
AC_SUBST(XNOISE_LIBS)

AC_CONFIG_FILES([Makefile
	data/Makefile
	data/misc/xnoise-1.0.pc
	data/misc/Makefile
	data/ui/Makefile
	src/Makefile
	src/xnoise/Makefile
	src/plugins/Makefile
	src/plugins/testplugin/Makefile
	src/plugins/titleToDecoration/Makefile
	src/plugins/leoslyrics/Makefile
	po/Makefile.in])

AC_OUTPUT

echo "
  Configuration Info:
    gettext_package:               ${GETTEXT_PACKAGE}
    prefix:                        ${prefix}
    vapidir:                       ${VAPIDIR}
    CFLAGS:                        ${CFLAGS}
    
  Plugins: 
    titleToDecoration plugin:      yes
    lyrics plugin:                 ${enable_lyrics}

"

