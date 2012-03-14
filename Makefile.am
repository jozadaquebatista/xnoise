NULL =

SUBDIRS = \
    data \
    libxnoise \
    src \
    plugins \
    po \
    doc \
    vapi \
    $(NULL)

DIST_SUBDIRS = \
    data \
    libxnoise \
    src \
    plugins \
    po \
    doc \
    vapi \
    tests \
    $(NULL)


if USE_VALA
  SUBDIRS += tests
endif

noinst_DATA =  \
    COPYING \
    AUTHORS \
    $(NULL)


EXTRA_DIST = \
    $(noinst_DATA) \
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
