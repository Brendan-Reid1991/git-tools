PREFIX     ?= $(HOME)/.local
BINDIR     ?= $(PREFIX)/bin
SHAREDIR   ?= $(PREFIX)/share/git-tools
DESTDIR    ?=

SCRIPTS       := git-superadd git-newbranch git-superpush
SUPPORT_FILES := git-tools-common.sh

SHELLCHECK ?= shellcheck

INSTALL_BIN   := $(DESTDIR)$(BINDIR)
INSTALL_SHARE := $(DESTDIR)$(SHAREDIR)

.PHONY: all install uninstall doctor test lint help

all: help

help:
	@echo "Targets:"
	@echo "  install     Install scripts to $(BINDIR), library to $(SHAREDIR)"
	@echo "  uninstall   Remove only the files this Makefile installs"
	@echo "  doctor      Verify install layout and PATH"
	@echo "  test        Run smoke tests"
	@echo "  lint        Run shellcheck on bin/, lib/, test/"
	@echo ""
	@echo "Variables: PREFIX=$(PREFIX) BINDIR=$(BINDIR) SHAREDIR=$(SHAREDIR) DESTDIR=$(DESTDIR)"

install:
	@install -d "$(INSTALL_BIN)" "$(INSTALL_SHARE)"
	@for file in $(SUPPORT_FILES); do \
		install -m 0644 "lib/$$file" "$(INSTALL_SHARE)/$$file"; \
	done
	@for script in $(SCRIPTS); do \
		awk -v lib='$(SHAREDIR)' ' \
			$$0 == "# git-tools-bootstrap:begin" { in_block = 1; \
				print "source \"$${GIT_TOOLS_LIB_DIR:-" lib "}/git-tools-common.sh\""; \
				next } \
			$$0 == "# git-tools-bootstrap:end"   { in_block = 0; next } \
			!in_block \
		' "bin/$$script" > "$(INSTALL_BIN)/$$script"; \
		chmod 0755 "$(INSTALL_BIN)/$$script"; \
	done
	@echo "Installed scripts to $(INSTALL_BIN)"
	@echo "Installed support files to $(INSTALL_SHARE)"

uninstall:
	@for script in $(SCRIPTS); do \
		rm -f "$(INSTALL_BIN)/$$script"; \
	done
	@for file in $(SUPPORT_FILES); do \
		rm -f "$(INSTALL_SHARE)/$$file"; \
	done
	@rmdir "$(INSTALL_SHARE)" 2>/dev/null || true
	@echo "Removed git-tools from $(INSTALL_BIN) and $(INSTALL_SHARE)"

doctor:
	@echo "Checking install health..."
	@case ":$$PATH:" in \
		*:"$(BINDIR)":*) ;; \
		*) echo "Warning: $(BINDIR) is not on PATH" ;; \
	esac
	@for script in $(SCRIPTS); do \
		if command -v "$$script" >/dev/null 2>&1; then \
			echo "OK: $$script -> $$(command -v "$$script")"; \
		else \
			echo "Missing: $$script"; \
		fi; \
	done
	@for file in $(SUPPORT_FILES); do \
		if [ -f "$(SHAREDIR)/$$file" ]; then \
			echo "OK: $$file -> $(SHAREDIR)/$$file"; \
		else \
			echo "Missing: $(SHAREDIR)/$$file"; \
		fi; \
	done

test:
	@bash test/smoke.sh

lint:
	@$(SHELLCHECK) -x bin/git-* lib/*.sh test/*.sh
