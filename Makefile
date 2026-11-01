# =============================================================================
# WebVeld Makefile
# =============================================================================
#
# WebVeld: Minimal subsets of HTML5 and CSS for resilient, auditable documents.
#
# Targets:
#   all               Verify syntax and prepare tools (default)
#   check / test      Run the complete test corpus
#   install           Install executables, data, man pages, docs, completions
#   install-bin       Install webveld-validate and webveld-profile-check
#   install-data      Install normative specification, profiles, conformance files
#   install-man       Install manual pages (man1, man7)
#   install-doc       Install documentation and examples
#   install-completions Install bash completion scripts
#   uninstall         Remove all installed files
#   man               Regenerate doc/man/*.1 and *.7 from their scdoc sources
#   dist              Reproducible source tarball in build/dist/
#   dist-bin          Reproducible installed contents tarball in build/dist/
#   help              Display help information
#
# Configuration variables (overridable via command line or environment):
#   PREFIX            Base directory for installation (default: /usr/local)
#   DESTDIR           Staging directory for staged/package installs (default: empty)
#   BINDIR            Directory for executables (default: $(PREFIX)/bin)
#   DATADIR           Directory for shared data (default: $(PREFIX)/share)
#   PKGDATADIR        Package data directory (default: $(DATADIR)/webveld)
#   DOCDIR            Documentation directory (default: $(DATADIR)/doc/webveld)
#   MANDIR            Manual page directory (default: $(DATADIR)/man)
#   BASHCOMPDIR       Bash completions directory (default: $(DATADIR)/bash-completion/completions)
# =============================================================================

# Directory variables
PREFIX          ?= /usr/local
DESTDIR         ?=
EXEC_PREFIX     ?= $(PREFIX)
BINDIR          ?= $(EXEC_PREFIX)/bin
DATAROOTDIR     ?= $(PREFIX)/share
DATADIR         ?= $(DATAROOTDIR)
PKGDATADIR      ?= $(DATADIR)/webveld
DOCDIR          ?= $(DATAROOTDIR)/doc/webveld
MANDIR          ?= $(DATAROOTDIR)/man
MAN1DIR         ?= $(MANDIR)/man1
MAN7DIR         ?= $(MANDIR)/man7
BASHCOMPDIR     ?= $(DATADIR)/bash-completion/completions

# Release version, read from the specification so it cannot drift
VERSION         := $(shell sed -n 's/^\*\*Version:\*\* \([0-9][0-9.]*\).*/\1/p' doc/webveld-spec.md)

# Release artifacts. <ver> is the tag without its leading "v" when HEAD is
# tagged, otherwise the spec version and commit. Tarballs are
# webveld-<ver>.tar.xz (source) and webveld-<ver>-noarch.tar.xz (the installed
# files, which are architecture-independent: nothing is compiled), timestamped
# with the commit time so the same commit always produces byte-identical files.
GIT_COMMIT      := $(shell git rev-parse --short=12 HEAD 2>/dev/null)
GIT_TAG         := $(shell git describe --tags --exact-match HEAD 2>/dev/null)
DIST_VERSION    := $(if $(GIT_TAG),$(patsubst v%,%,$(GIT_TAG)),$(VERSION)-g$(GIT_COMMIT))
DIST_NAME       := webveld-$(DIST_VERSION)
DIST_BIN_NAME   ?= $(DIST_NAME)-noarch
DIST_DIR        := build/dist
DIST_STAGE      := build/dist-stage
SOURCE_DATE_EPOCH ?= $(shell git log -1 --format=%ct HEAD 2>/dev/null)

# Tool variables
LUA             ?= lua
LUAC            ?= luac
SED             ?= sed
SH              ?= sh
INSTALL         ?= install
INSTALL_PROGRAM ?= $(INSTALL) -m 755
INSTALL_SCRIPT  ?= $(INSTALL) -m 755
INSTALL_DATA    ?= $(INSTALL) -m 644
INSTALL_DIR     ?= $(INSTALL) -d -m 755
LN_S            ?= ln -sf
RM              ?= rm -f
RMDIR           ?= rmdir
TAR             ?= tar
XZ              ?= xz
SHA256SUM       ?= sha256sum
SCDOC           ?= scdoc
MIN_SCDOC_VERSION ?= 1.11.5

# Man pages are written in scdoc (doc/man/*.scd) and the generated roff is
# committed, so installing never needs scdoc. "make man" regenerates them.
MAN_PAGES       := doc/man/webveld.7 doc/man/webveld-validate.1 doc/man/webveld-profile-check.1

# Deterministic archive options (GNU tar; xz runs single-threaded so output is stable): sorted names, commit timestamp,
# numeric root ownership, and normalized permissions (no setuid or setgid bits).
REPRO_TAR        = $(TAR) --sort=name --format=gnu --mtime=@$(SOURCE_DATE_EPOCH) \
                   --owner=0 --group=0 --numeric-owner --mode='u+rwX,go+rX,go-w,a-s'

# Default target
.PHONY: all
all:
	@echo "Checking Lua syntax for WebVeld tools..."
	@$(LUAC) -p tools/validator/webveld-validate.lua
	@$(LUAC) -p tools/validator/webveld-profile-check.lua
	@$(LUAC) -p tools/validator/verify-conformance-coverage.lua
	@$(LUAC) -p tools/validator/test-validator.lua
	@$(LUAC) -p tools/validator/test-profile-check.lua
	@$(LUAC) -p tools/corpus-study/analyze.lua
	@$(LUAC) -p tools/corpus-study/classify-floats.lua
	@$(LUAC) -p tools/corpus-study/classify-grid.lua
	@$(LUAC) -p tools/render-diff/run_diff.lua
	@$(LUAC) -p tools/render-diff/compare_content.lua
	@echo "All tools compiled OK. Run 'make check' to test or 'make install' to install."

# -----------------------------------------------------------------------------
# Testing
# -----------------------------------------------------------------------------
.PHONY: check test
check: test

test:
	@echo "=== WebVeld Test Suite ==="
	@echo "1. Validator test corpus:"
	@$(LUA) tools/validator/test-validator.lua
	@echo ""
	@echo "2. Profile checker test corpus:"
	@$(LUA) tools/validator/test-profile-check.lua
	@echo ""
	@echo "3. Render conformance coverage audit:"
	@$(LUA) tools/validator/verify-conformance-coverage.lua
	@echo ""
	@echo "4. Repository HTML subset conformance:"
	@$(SH) tools/validator/check-repo.sh
	@echo ""
	@echo "5. Man pages match their scdoc sources:"
	@$(MAKE) -s man-check
	@echo ""
	@echo "All WebVeld tests passed!"

# -----------------------------------------------------------------------------
# Man pages
# -----------------------------------------------------------------------------
.PHONY: man man-check check-scdoc-man

check-scdoc-man:
	@if ! command -v $(SCDOC) > /dev/null 2>&1; then \
		echo "ERROR: $(SCDOC) is required to build man pages." >&2; exit 1; \
	fi; \
	scdoc_ver=$$($(SCDOC) -v 2>/dev/null | awk '{print $$2}'); \
	if [ -z "$$scdoc_ver" ] || ! $(LUA) -e 'local function p(s) local a,b,c=s:match("(%d+)%.(%d+)%.?(%d*)"); return {tonumber(a) or 0,tonumber(b) or 0,tonumber(c) or 0} end; local function ge(x,y) for i=1,3 do if x[i]>y[i] then return 0 elseif x[i]<y[i] then return 1 end end return 0 end; os.exit(ge(p("'$$scdoc_ver'"), p("$(MIN_SCDOC_VERSION)")))' 2>/dev/null; then \
		echo "ERROR: $(SCDOC) >= $(MIN_SCDOC_VERSION) is required to build man pages (found $${scdoc_ver:-unknown})." >&2; \
		exit 1; \
	fi

man: check-scdoc-man $(MAN_PAGES)

# @VERSION@ is filled in from the spec. The page date is the last commit of the
# .scd source (or today, if it is uncommitted), so regenerating unchanged
# sources gives unchanged output.
define scdoc-render
	epoch=$$(git log -1 --format=%ct -- $(1) 2>/dev/null); \
	epoch=$${epoch:-$$SOURCE_DATE_EPOCH}; \
	sed 's/@VERSION@/$(VERSION)/g' $(1) | SOURCE_DATE_EPOCH=$${epoch:-$$(date +%s)} $(SCDOC)
endef

doc/man/%.1: doc/man/%.1.scd doc/webveld-spec.md | check-scdoc-man
	@$(call scdoc-render,$<) > $@.tmp && mv $@.tmp $@ && echo "Generated $@"

doc/man/%.7: doc/man/%.7.scd doc/webveld-spec.md | check-scdoc-man
	@$(call scdoc-render,$<) > $@.tmp && mv $@.tmp $@ && echo "Generated $@"

# Fails if a committed man page is stale. The scdoc version comment and the
# page date are ignored, so only real content or version drift counts.
# Skipped if scdoc is not installed or older than $(MIN_SCDOC_VERSION).
MAN_NORMALIZE    = -e '/^\.\\"/d' -e 's/^\(\.TH "[^"]*" "[^"]*"\) "[^"]*"/\1 ""/'
man-check:
	@if ! command -v $(SCDOC) > /dev/null 2>&1; then \
		echo "  SKIP: $(SCDOC) not installed"; exit 0; \
	fi; \
	scdoc_ver=$$($(SCDOC) -v 2>/dev/null | awk '{print $$2}'); \
	if [ -z "$$scdoc_ver" ] || ! $(LUA) -e 'local function p(s) local a,b,c=s:match("(%d+)%.(%d+)%.?(%d*)"); return {tonumber(a) or 0,tonumber(b) or 0,tonumber(c) or 0} end; local function ge(x,y) for i=1,3 do if x[i]>y[i] then return 0 elseif x[i]<y[i] then return 1 end end return 0 end; os.exit(ge(p("'$$scdoc_ver'"), p("$(MIN_SCDOC_VERSION)")))' 2>/dev/null; then \
		echo "  SKIP: $(SCDOC) >= $(MIN_SCDOC_VERSION) required (found $${scdoc_ver:-unknown}); skipping man page check"; exit 0; \
	fi; \
	dir=build/man-check; mkdir -p $$dir; status=0; \
	for page in $(MAN_PAGES); do \
		$(call scdoc-render,$$page.scd) > $$dir/fresh || exit 1; \
		sed $(MAN_NORMALIZE) $$page > $$dir/committed.norm; \
		sed $(MAN_NORMALIZE) $$dir/fresh > $$dir/fresh.norm; \
		if cmp -s $$dir/committed.norm $$dir/fresh.norm; then \
			echo "  PASS: $$page"; \
		else \
			echo "  FAIL: $$page is out of date; run 'make man' and commit the result"; status=1; \
		fi; \
	done; \
	$(RM) -r $$dir; exit $$status

# -----------------------------------------------------------------------------
# Installation
# -----------------------------------------------------------------------------
.PHONY: install install-bin install-data install-man install-doc install-completions

install: install-bin install-data install-man install-doc install-completions
	@echo "WebVeld successfully installed to $(DESTDIR)$(PREFIX)"

install-bin:
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
	$(SED) -e 's|@@PKGDATADIR@@|$(PKGDATADIR)|g' tools/validator/webveld-validate.lua > $(DESTDIR)$(BINDIR)/webveld-validate.tmp
	$(INSTALL_SCRIPT) $(DESTDIR)$(BINDIR)/webveld-validate.tmp $(DESTDIR)$(BINDIR)/webveld-validate
	$(RM) $(DESTDIR)$(BINDIR)/webveld-validate.tmp
	$(SED) -e 's|@@PKGDATADIR@@|$(PKGDATADIR)|g' tools/validator/webveld-profile-check.lua > $(DESTDIR)$(BINDIR)/webveld-profile-check.tmp
	$(INSTALL_SCRIPT) $(DESTDIR)$(BINDIR)/webveld-profile-check.tmp $(DESTDIR)$(BINDIR)/webveld-profile-check
	$(RM) $(DESTDIR)$(BINDIR)/webveld-profile-check.tmp
	cd $(DESTDIR)$(BINDIR) && $(LN_S) webveld-validate webveld-validate.lua
	cd $(DESTDIR)$(BINDIR) && $(LN_S) webveld-profile-check webveld-profile-check.lua

install-data:
	$(INSTALL_DIR) $(DESTDIR)$(PKGDATADIR)
	$(INSTALL_DIR) $(DESTDIR)$(PKGDATADIR)/doc
	$(INSTALL_DIR) $(DESTDIR)$(PKGDATADIR)/doc/profiles
	$(INSTALL_DIR) $(DESTDIR)$(PKGDATADIR)/profiles
	$(INSTALL_DIR) $(DESTDIR)$(PKGDATADIR)/conformance
	$(INSTALL_DATA) doc/webveld-spec.md $(DESTDIR)$(PKGDATADIR)/webveld-spec.md
	$(INSTALL_DATA) doc/webveld-spec.md $(DESTDIR)$(PKGDATADIR)/doc/webveld-spec.md
	$(INSTALL_DATA) doc/profiles/webveld-nano.md $(DESTDIR)$(PKGDATADIR)/profiles/webveld-nano.md
	$(INSTALL_DATA) doc/profiles/webveld-nano.md $(DESTDIR)$(PKGDATADIR)/doc/profiles/webveld-nano.md
	$(INSTALL_DATA) doc/profiles/webveld-pico.md $(DESTDIR)$(PKGDATADIR)/profiles/webveld-pico.md
	$(INSTALL_DATA) doc/profiles/webveld-pico.md $(DESTDIR)$(PKGDATADIR)/doc/profiles/webveld-pico.md
	for f in conformance/*.html conformance/README.md; do \
		[ -f "$$f" ] && $(INSTALL_DATA) "$$f" $(DESTDIR)$(PKGDATADIR)/conformance/ || exit 1; \
	done

install-man:
	$(INSTALL_DIR) $(DESTDIR)$(MAN1DIR)
	$(INSTALL_DIR) $(DESTDIR)$(MAN7DIR)
	$(INSTALL_DATA) doc/man/webveld-validate.1 $(DESTDIR)$(MAN1DIR)/webveld-validate.1
	$(INSTALL_DATA) doc/man/webveld-profile-check.1 $(DESTDIR)$(MAN1DIR)/webveld-profile-check.1
	$(INSTALL_DATA) doc/man/webveld.7 $(DESTDIR)$(MAN7DIR)/webveld.7

install-doc:
	$(INSTALL_DIR) $(DESTDIR)$(DOCDIR)
	$(INSTALL_DIR) $(DESTDIR)$(DOCDIR)/profiles
	$(INSTALL_DIR) $(DESTDIR)$(DOCDIR)/media/logo
	$(INSTALL_DIR) $(DESTDIR)$(DOCDIR)/examples/minimal-site
	$(INSTALL_DIR) $(DESTDIR)$(DOCDIR)/examples/payment_processor
	$(INSTALL_DATA) README.md $(DESTDIR)$(DOCDIR)/README.md
	$(INSTALL_DATA) LICENSE $(DESTDIR)$(DOCDIR)/LICENSE
	for f in doc/*.md; do \
		[ -f "$$f" ] && $(INSTALL_DATA) "$$f" $(DESTDIR)$(DOCDIR)/ || exit 1; \
	done
	for f in doc/profiles/*.md; do \
		[ -f "$$f" ] && $(INSTALL_DATA) "$$f" $(DESTDIR)$(DOCDIR)/profiles/ || exit 1; \
	done
	for f in media/logo/*; do \
		[ -f "$$f" ] && $(INSTALL_DATA) "$$f" $(DESTDIR)$(DOCDIR)/media/logo/ || exit 1; \
	done
	for f in examples/minimal-site/*; do \
		[ -f "$$f" ] && $(INSTALL_DATA) "$$f" $(DESTDIR)$(DOCDIR)/examples/minimal-site/ || exit 1; \
	done
	for f in examples/payment_processor/*; do \
		[ -f "$$f" ] && $(INSTALL_DATA) "$$f" $(DESTDIR)$(DOCDIR)/examples/payment_processor/ || exit 1; \
	done

install-completions:
	$(INSTALL_DIR) $(DESTDIR)$(BASHCOMPDIR)
	$(INSTALL_DATA) completions/bash/webveld-validate $(DESTDIR)$(BASHCOMPDIR)/webveld-validate
	$(INSTALL_DATA) completions/bash/webveld-profile-check $(DESTDIR)$(BASHCOMPDIR)/webveld-profile-check

# -----------------------------------------------------------------------------
# Uninstallation
# -----------------------------------------------------------------------------
.PHONY: uninstall uninstall-bin uninstall-data uninstall-man uninstall-doc uninstall-completions

uninstall: uninstall-bin uninstall-data uninstall-man uninstall-doc uninstall-completions
	@echo "WebVeld successfully uninstalled from $(DESTDIR)$(PREFIX)"

uninstall-bin:
	$(RM) $(DESTDIR)$(BINDIR)/webveld-validate
	$(RM) $(DESTDIR)$(BINDIR)/webveld-validate.lua
	$(RM) $(DESTDIR)$(BINDIR)/webveld-profile-check
	$(RM) $(DESTDIR)$(BINDIR)/webveld-profile-check.lua
	-$(RMDIR) $(DESTDIR)$(BINDIR) 2>/dev/null || true

uninstall-data:
	$(RM) -r $(DESTDIR)$(PKGDATADIR)

uninstall-man:
	$(RM) $(DESTDIR)$(MAN1DIR)/webveld-validate.1
	$(RM) $(DESTDIR)$(MAN1DIR)/webveld-profile-check.1
	$(RM) $(DESTDIR)$(MAN7DIR)/webveld.7
	-$(RMDIR) $(DESTDIR)$(MAN1DIR) 2>/dev/null || true
	-$(RMDIR) $(DESTDIR)$(MAN7DIR) 2>/dev/null || true

uninstall-doc:
	$(RM) -r $(DESTDIR)$(DOCDIR)

uninstall-completions:
	$(RM) $(DESTDIR)$(BASHCOMPDIR)/webveld-validate
	$(RM) $(DESTDIR)$(BASHCOMPDIR)/webveld-profile-check
	-$(RMDIR) $(DESTDIR)$(BASHCOMPDIR) 2>/dev/null || true

# -----------------------------------------------------------------------------
# Cleanup and Help
# -----------------------------------------------------------------------------
.PHONY: clean help dist dist-bin

clean:
	$(RM) -r tmp/test-install
	$(RM) -r build

dist:
	@test -n "$(GIT_COMMIT)" || { echo "make dist must run in a git checkout" >&2; exit 1; }
	@git diff --quiet HEAD -- || echo "note: uncommitted changes are not included; dist is built from HEAD ($(GIT_COMMIT))"
	mkdir -p $(DIST_DIR)
	$(RM) -r $(DIST_STAGE)
	mkdir -p $(DIST_STAGE)/$(DIST_NAME)
	git archive --format=tar HEAD | (cd $(DIST_STAGE)/$(DIST_NAME) && $(TAR) --no-same-owner -xf -)
	cd $(DIST_STAGE) && $(REPRO_TAR) -cf $(CURDIR)/$(DIST_DIR)/$(DIST_NAME).tar $(DIST_NAME)
	$(RM) -r $(DIST_STAGE)
	$(RM) $(DIST_DIR)/$(DIST_NAME).tar.xz
	$(XZ) -9 -T1 $(DIST_DIR)/$(DIST_NAME).tar
	cd $(DIST_DIR) && $(SHA256SUM) *.tar.xz > SHA256SUMS
	@echo "Source tarball for $(DIST_NAME) (commit $(GIT_COMMIT)) in $(DIST_DIR)/:"
	@cat $(DIST_DIR)/SHA256SUMS

dist-bin:
	@test -n "$(GIT_COMMIT)" || { echo "make dist-bin must run in a git checkout" >&2; exit 1; }
	@git diff --quiet HEAD -- || echo "note: uncommitted changes are not included; dist-bin is built from HEAD ($(GIT_COMMIT))"
	mkdir -p $(DIST_DIR)
	$(RM) -r $(DIST_STAGE)
	mkdir -p $(DIST_STAGE)/src $(DIST_STAGE)/install-root
	git archive --format=tar HEAD | (cd $(DIST_STAGE)/src && $(TAR) --no-same-owner -xf -)
	$(MAKE) -s -C $(DIST_STAGE)/src install DESTDIR=$(CURDIR)/$(DIST_STAGE)/install-root PREFIX=$(PREFIX) > /dev/null
	cd $(DIST_STAGE)/install-root && $(REPRO_TAR) -cf $(CURDIR)/$(DIST_DIR)/$(DIST_BIN_NAME).tar .
	$(RM) -r $(DIST_STAGE)
	$(RM) $(DIST_DIR)/$(DIST_BIN_NAME).tar.xz
	$(XZ) -9 -T1 $(DIST_DIR)/$(DIST_BIN_NAME).tar
	cd $(DIST_DIR) && $(SHA256SUM) *.tar.xz > SHA256SUMS
	@echo "Installed binary tarball for $(DIST_BIN_NAME) (commit $(GIT_COMMIT)) in $(DIST_DIR)/:"
	@cat $(DIST_DIR)/SHA256SUMS

help:
	@echo "WebVeld Makefile targets:"
	@echo "  all                 Syntax check scripts and verify readiness"
	@echo "  check / test        Run full test suite"
	@echo "  dist                Build reproducible source tarball in $(DIST_DIR)/"
	@echo "  dist-bin            Build reproducible installed contents tarball in $(DIST_DIR)/"
	@echo "  install             Install binaries, data, man pages, docs, completions"
	@echo "  man                 Regenerate man pages from their scdoc sources (needs scdoc >= $(MIN_SCDOC_VERSION))"
	@echo "  install-bin         Install only binaries ($(BINDIR))"
	@echo "  install-data        Install only specification and conformance data ($(PKGDATADIR))"
	@echo "  install-man         Install only manual pages ($(MANDIR))"
	@echo "  install-doc         Install only documentation and examples ($(DOCDIR))"
	@echo "  install-completions Install only bash completions ($(BASHCOMPDIR))"
	@echo "  uninstall           Uninstall all files"
	@echo "  clean               Remove temporary test installations and build artifacts"
	@echo ""
	@echo "Configuration variables:"
	@echo "  PREFIX              Installation prefix (current: $(PREFIX))"
	@echo "  DESTDIR             Staging directory (current: $(DESTDIR))"
	@echo "  BINDIR              Binaries directory (current: $(BINDIR))"
	@echo "  DATADIR             Data directory (current: $(DATADIR))"
	@echo "  PKGDATADIR          Package data directory (current: $(PKGDATADIR))"
	@echo "  DOCDIR              Documentation directory (current: $(DOCDIR))"
	@echo "  MANDIR              Manual page directory (current: $(MANDIR))"
	@echo "  BASHCOMPDIR         Completions directory (current: $(BASHCOMPDIR))"
