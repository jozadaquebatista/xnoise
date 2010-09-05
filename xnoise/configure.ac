AC_PREREQ(2.53)

#xnoise version
m4_define(xnoise_major_version, 0)
m4_define(xnoise_minor_version, 1)
m4_define(xnoise_micro_version, 10)
m4_define(xnoise_version, xnoise_major_version.xnoise_minor_version.xnoise_micro_version)

#libplaylist version
m4_define(libplaylist_major_version, 0)
m4_define(libplaylist_minor_version, 0)
m4_define(libplaylist_micro_version, 1)
m4_define(libplaylist_version, libplaylist_major_version.libplaylist_minor_version.libplaylist_micro_version)

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
LIBXML_REQUIRED=2.6.32
GIO_REQUIRED=2.16
GTK_REQUIRED=2.18.0
SQLITE_REQUIRED=3.4
TAGLIB_C_REQUIRED=1.5.0

dnl required versions for vala, if used
VALA_REQUIRED=0.9.8

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
    unique-1.0)

PKG_CHECK_MODULES(LIBPLAYLIST, \
    glib-2.0 >= $GLIB_REQUIRED \
    gobject-2.0 >= $GLIB_REQUIRED \
    libxml-2.0 >= $LIBXML_REQUIRED \
    gio-2.0 >= $GIO_REQUIRED)

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


dnl VAPIDIR is used to place the xnoise vapi file
VAPIDIR="${datadir}/vala-0.10/vapi"
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
    data/misc/libplaylist-1.0.pc
    data/ui/Makefile
    data/icons/Makefile
    data/icons/32x32/Makefile
    data/icons/48x48/Makefile
    data/icons/256x256/Makefile
    data/icons/scalable/Makefile
    src/Makefile
    libplaylist/Makefile
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

"
