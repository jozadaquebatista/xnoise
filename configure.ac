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

GLIB_REQUIRED=2.12.0
GTK_REQUIRED=2.16.0
SQLITE_REQUIRED=3.4

PKG_CHECK_MODULES(XNOISE, glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gtk+-2.0 >= $GTK_REQUIRED taglib_c sqlite3 >= $SQLITE_REQUIRED gstreamer-0.10 gstreamer-interfaces-0.10 gstreamer-plugins-base-0.10 gdk-2.0 gdk-pixbuf-2.0 gdk-x11-2.0 gio-2.0 unique-1.0 gmodule-2.0)

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
	po/Makefile.in])

AC_OUTPUT

echo "

    Configuration Info:

    gettext_package:               ${GETTEXT_PACKAGE}
    prefix:                        ${prefix}
    vapidir:                       ${VAPIDIR}
    CFLAGS:                        ${CFLAGS}
    C Compiler:                    ${CC}

    Now type 'make' to compile xnoise.

"
