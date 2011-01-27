NULL =

SUBDIRS = \
    data \
    src \
    libplaylist \
    po \
    vapi \
    tests \
    $(NULL)

DIST_SUBDIRS = \
    data \
    src \
    libplaylist \
    plugins \
    po \
    vapi \
    tests \
    $(NULL)

xnoiselicense_DATA =  \
    COPYING \
    AUTHORS \
    $(NULL)

xnoiselicensedir = $(datadir)/xnoise/license

EXTRA_DIST = \
    $(xnoiselicense_DATA) \
    intltool-extract.in \
    intltool-merge.in \
    intltool-update.in\
    $(NULL)

DISTCLEANFILES = \
    intltool-extract.in \
    intltool-merge.in \
    intltool-update.in \
    configure \
    ltmain.sh \
    Makefile.in \
    config.h.in \
    compile \
    depcomp \
    install-sh \
    missing \
    mkinstalldirs \
    autom4te.cache/output.0 \
    autom4te.cache/output.1 \
    autom4te.cache/requests \
    autom4te.cache/traces.0 \
    autom4te.cache/traces.1 \
    config.guess \
    config.sub \
    aclocal.m4 \
    po/.intltool-merge-cache \
    $(NULL)


ACLOCAL_AMFLAGS = -I m4
