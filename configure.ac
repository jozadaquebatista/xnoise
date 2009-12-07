m4_define(xnoise_major_version, 0)
m4_define(xnoise_minor_version, 1)
m4_define(xnoise_micro_version, 0)
m4_define(xnoise_version, xnoise_major_version.xnoise_minor_version.xnoise_micro_version)


AC_INIT(xnoise, xnoise_version, shuerhaak en(at)SPAMFREE g o ogl ema il (dot)com, [xnoise])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_MACRO_DIR([m4])
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

GLIB_REQUIRED=2.12.0
GTK_REQUIRED=2.16.0
SQLITE_REQUIRED=3.4
PKG_CHECK_MODULES(XNOISE, glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gtk+-2.0 >= $GTK_REQUIRED taglib_c sqlite3 >= $SQLITE_REQUIRED gstreamer-0.10 gstreamer-interfaces-0.10 gstreamer-plugins-base-0.10 gdk-2.0 gdk-pixbuf-2.0 gdk-x11-2.0 gio-2.0 unique-1.0 gmodule-2.0)



dnl ================================================================
dnl plugin check for plugins dependent on libxml-2.0

LIBXML_REQUIRED=2.7.5
AC_ARG_ENABLE([lyrics],
	AS_HELP_STRING([--disable-leoslyrics],
	[Disable lyric plugin (default: enabled)]),
	[enable_leoslyrics=$enableval],
	[enable_leoslyrics=yes])

PKG_CHECK_MODULES(LIBXML, \
				  libxml-2.0 >= $LIBXML_REQUIRED, \
				  have_libxml=yes, \
				  have_libxml=no)
if test "x$have_libxml" = "xno"; then
	AC_MSG_WARN([libxml $LIBXML_REQUIRED or greater not found.])
fi
dnl ================================================================




dnl ================================================================
dnl plugin check for plugins dependent on libsoup-2.4

LIBSOUP_REQUIRED=2.28.1
PKG_CHECK_MODULES(LIBSOUP, \
				  libsoup-2.4 >= $LIBSOUP_REQUIRED, \
				  have_libsoup=yes, \
				  have_libsoup=no)
if test "x$have_libsoup" != "xyes"; then
	AC_MSG_WARN([libsoup $LIBSOUP_REQUIRED or greater not found.])
fi
dnl ================================================================




dnl ================================================================
dnl dependency check for optional build of leoslyrics plugin 

if test "x$enable_leoslyrics" = "xyes"; then
	if test "x$have_libxml" = "xyes" && test "x$have_libsoup" = "xyes"; then
		enable_leoslyrics=yes		
	else
		enable_leoslyrics=no
        AC_MSG_WARN([lyrics plugin will not be included in the build.])
	fi
fi
AM_CONDITIONAL(ENABLE_LEOSLYRICS, test x"$enable_leoslyrics" = "xyes")
dnl ================================================================




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
    leoslyrics plugin:             ${enable_leoslyrics}

"
