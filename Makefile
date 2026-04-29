PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
SCRIPTS := git-superadd git-newbranch git-superpush
LIBS := git-tools-common.sh

.PHONY: install uninstall doctor test

install:
	@mkdir -p "$(BINDIR)" "$(LIBDIR)"
	@for script in $(SCRIPTS); do \
		install -m 0755 "bin/$$script" "$(BINDIR)/$$script"; \
	done
	@for lib in $(LIBS); do \
		install -m 0644 "lib/$$lib" "$(LIBDIR)/$$lib"; \
	done
	@echo "Installed scripts to $(BINDIR) and libraries to $(LIBDIR)"

uninstall:
	@for script in $(SCRIPTS); do \
		rm -f "$(BINDIR)/$$script"; \
	done
	@for lib in $(LIBS); do \
		rm -f "$(LIBDIR)/$$lib"; \
	done
	@echo "Removed scripts from $(BINDIR) and libraries from $(LIBDIR)"

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
	@for lib in $(LIBS); do \
		if [ -f "$(LIBDIR)/$$lib" ]; then \
			echo "OK: $$lib -> $(LIBDIR)/$$lib"; \
		else \
			echo "Missing: $$lib in $(LIBDIR)"; \
		fi; \
	done

test:
	@bash test/smoke.sh
