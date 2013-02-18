include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
    -include $(CONFIG_HEADER) \
	-I$(top_srcdir)/libxnoise \
    -DXN_TESTDIR=\"$(top_srcdir)/tests/\" \
	$(XNOISE_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(GLIB_LIBS) \
              ../libxnoise/libxnoise.la \
              -lm \
              $(XNOISE_LIBS)

BUILT_SOURCES = tests.vala.stamp

TEST_PROGS += tests
tests_VALASOURCES = \
       test.vala \
       $(NULL)

tests_DEPENDENCIES = $(top_srcdir)/libxnoise/xnoise-1.0.vapi

tests_SOURCES = tests.vala.stamp $(tests_VALASOURCES:.vala=.c)
tests.vala.stamp: $(tests_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) --vapidir $(top_srcdir)/libxnoise --vapidir $(top_srcdir)/vapi --pkg xnoise-1.0 --pkg gio-2.0 --pkg posix --pkg config $^
	touch $@
tests_LDADD = $(progs_ldadd)

EXTRA_DIST += $(tests_VALASOURCES)

coverage-reset:
	lcov --base-directory=@top_srcdir@ --directory @top_srcdir@/src --zerocounters

coverage-report:
	lcov --directory @top_srcdir@/src \
		--capture \
		--output-file @top_builddir@/lcov.info

	lcov --directory @top_srcdir@/src \
		--output-file @top_builddir@/lcov.info \
		--remove @top_builddir@/lcov.info \
		"/usr/include/*" "*.c" "*.h" "*.vapi"

	@echo
	@echo 'lcov report can be found in:'
	@echo 'file://@abs_top_builddir@/tests/coverage/index.html'
	@echo

clean-local:
	-rm -rf coverage

.PHONY: coverage-report

EXTRA_DIST += \
	playlist-examples \
	$(NULL)


CLEANFILES = \
	*.c \
	tests.vala.stamp \
	$(NULL)
	
DISTCLEANFILES = \
	Makefile.in \
	$(NULL)


