PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
SCRIPTS := git-superadd git-newbranch git-superpush
SUPPORT_FILES := git-tools-common.sh

.PHONY: install uninstall doctor test

install:
	@mkdir -p "$(BINDIR)"
	@for script in $(SCRIPTS); do \
		install -m 0755 "bin/$$script" "$(BINDIR)/$$script"; \
	done
	@for file in $(SUPPORT_FILES); do \
		install -m 0644 "lib/$$file" "$(BINDIR)/$$file"; \
	done
	@echo "Installed scripts and support files to $(BINDIR)"

uninstall:
	@for script in $(SCRIPTS); do \
		rm -f "$(BINDIR)/$$script"; \
	done
	@for file in $(SUPPORT_FILES); do \
		rm -f "$(BINDIR)/$$file"; \
	done
	@echo "Removed scripts and support files from $(BINDIR)"

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
		if [ -f "$(BINDIR)/$$file" ]; then \
			echo "OK: $$file -> $(BINDIR)/$$file"; \
		else \
			echo "Missing: $$file in $(BINDIR)"; \
		fi; \
	done

test:
	@bash test/smoke.sh
