NULL =

SUBDIRS = \
    data \
    libxnoise \
    src \
    packaging \
    plugins \
    po \
    doc \
    utils \
    vapi \
    $(NULL)

DIST_SUBDIRS = \
    data \
    libxnoise \
    src \
    packaging \
    plugins \
    po \
    doc \
    utils \
    vapi \
    tests \
    $(NULL)


if USE_VALA
  SUBDIRS += tests
endif

noinst_DATA =  \
    COPYING \
    MAINTAINERS \
    AUTHORS \
    xnoise.doap \
    package_chef.sh \
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


.PHONY: ChangeLog

ChangeLog: Makefile
	(GIT_DIR=$(top_srcdir)/.git git log > .changelog.tmp \
	&& mv .changelog.tmp ChangeLog; rm -f .changelog.tmp) \
	|| (touch ChangeLog; echo 'Git directory not found: installing possibly empty changelog.' >&2)

dist-hook: ChangeLog

