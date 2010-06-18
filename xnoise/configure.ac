AC_PREREQ(2.53)
m4_define(xnoise_major_version, 0)
m4_define(xnoise_minor_version, 1)
m4_define(xnoise_micro_version, 4)
m4_define(xnoise_version, xnoise_major_version.xnoise_minor_version.xnoise_micro_version)

AC_INIT(xnoise, xnoise_version, shuerhaakenATgo oglemail.com, [xnoise])

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
GIO_REQUIRED=2.16
GTK_REQUIRED=2.18.0
SQLITE_REQUIRED=3.4
TAGLIB_C_REQUIRED=1.5.0
VALA_REQUIRED=0.8.0

AC_PROG_CC
AM_PROG_VALAC($VALA_REQUIRED)
AC_STDC_HEADERS
AC_PROG_LIBTOOL
AC_FUNC_MMAP

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
    --pkg gstreamer-pbutils-0.10 \
    --pkg gstreamer-interfaces-0.10 \
    --pkg taglib_c \
    --pkg unique-1.0 \
    --pkg gmodule-2.0 \
"

AC_SUBST(XNOISE_CFLAGS)
AC_SUBST(XNOISE_LIBS)
AC_SUBST(XNOISE_PACKAGES)

dnl ================================================================
dnl check for vala to setup vapidir
PKG_CHECK_MODULES(VALAC, \
                  vala-1.0 >= $VALA_REQUIRED, \
                  have_vala=yes, \
                  have_vala=no)

if test x$have_vala = xyes ; then
    if test "x$VALAC" = "x"; then
        AC_MSG_ERROR([Cannot find the "valac" compiler in PATH])
    fi
fi
dnl VAPIDIR is used to place the xnoise vapi file
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
    data/icons/Makefile
    data/icons/32x32/Makefile
    data/icons/48x48/Makefile
    data/icons/256x256/Makefile
    data/icons/scalable/Makefile
    src/Makefile
    po/Makefile.in
])

AC_OUTPUT

echo "
  ${PACKAGE} ${VERSION}
  ~~~~~~~~~~~~
  
  Configuration Info:
    gettext_package:               ${GETTEXT_PACKAGE}
    prefix:                        ${prefix}
    CFLAGS:                        ${CFLAGS}

"
