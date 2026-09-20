PREFIX     ?= $(HOME)/.local
BINDIR     ?= $(PREFIX)/bin
SHAREDIR   ?= $(PREFIX)/share/gra
DESTDIR    ?=

COMMANDS := $(wildcard lib/commands/*.sh)
SHELLCHECK ?= shellcheck

INSTALL_BIN   := $(DESTDIR)$(BINDIR)
INSTALL_SHARE := $(DESTDIR)$(SHAREDIR)

.PHONY: all install uninstall test lint help

all: help

help:
	@echo "Targets: install uninstall test lint help"
	@echo "Executable: $(BINDIR)/gra"
	@echo "Libraries:  $(SHAREDIR)"
	@echo "Overrides: PREFIX BINDIR SHAREDIR DESTDIR SHELLCHECK"

install:
	@install -d "$(INSTALL_BIN)" "$(INSTALL_SHARE)/commands"
	@install -m 0644 lib/common.sh "$(INSTALL_SHARE)/common.sh"
	@install -m 0644 $(COMMANDS) "$(INSTALL_SHARE)/commands/"
	@awk -v commands='$(SHAREDIR)/commands' ' \
		/# gra-install-path$$/ { print "commands_dir=\"" commands "\""; next } \
		{ print } \
	' bin/gra > "$(INSTALL_BIN)/gra"
	@chmod 0755 "$(INSTALL_BIN)/gra"
	@echo "Installed gra to $(INSTALL_BIN)/gra"

uninstall:
	@rm -f "$(INSTALL_BIN)/gra" "$(INSTALL_SHARE)/common.sh"
	@set -e; for file in $(notdir $(COMMANDS)); do \
		rm -f "$(INSTALL_SHARE)/commands/$$file"; \
	done
	@rmdir "$(INSTALL_SHARE)/commands" "$(INSTALL_SHARE)" 2>/dev/null || true
	@echo "Removed gra from $(INSTALL_BIN)"

test:
	@bash test/smoke.sh

lint:
	@$(SHELLCHECK) -x bin/gra lib/common.sh $(COMMANDS) test/*.sh
