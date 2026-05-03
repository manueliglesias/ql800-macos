LABEL        = dev.iglesias.ql800
PROJECT_DIR  = $(CURDIR)
INSTALL_DIR  = $(HOME)/Library/Application Support/$(LABEL)
PLIST_SRC    = $(PROJECT_DIR)/dev.iglesias.ql800.plist.template
PLIST_DST    = $(HOME)/Library/LaunchAgents/$(LABEL).plist
PDF_SERVICE  = $(HOME)/Library/PDF Services/Print to QL-800.sh
VENV_DIR     = $(INSTALL_DIR)/.venv
VENV_PYTHON  = $(VENV_DIR)/bin/python3
VENV_PIP     = $(VENV_DIR)/bin/pip
UID          := $(shell id -u)

.PHONY: deploy undeploy reload venv install-files install-venv

deploy: undeploy install-files install-venv
	@"$(VENV_PYTHON)" -c "import brother_ql" || \
		(echo "Missing brother_ql in installed venv. Run: make venv" >&2; exit 1)
	sed 's|__INSTALL_DIR__|$(INSTALL_DIR)|g' "$(PLIST_SRC)" > "$(PLIST_DST)"
	launchctl bootstrap gui/$(UID) "$(PLIST_DST)"
	@echo "Deployed. Test with: launchctl list | grep ql800"

install-files:
	mkdir -p /tmp/ql800_pending
	mkdir -p "$(INSTALL_DIR)"
	mkdir -p "$(HOME)/Library/PDF Services"
	mkdir -p "$(HOME)/Library/LaunchAgents"
	cp "$(PROJECT_DIR)/Print to QL-800.sh" "$(PDF_SERVICE)"
	cp "$(PROJECT_DIR)/worker.sh" "$(INSTALL_DIR)/worker.sh"
	cp "$(PROJECT_DIR)/print_label.py" "$(INSTALL_DIR)/print_label.py"
	cp "$(PROJECT_DIR)/requirements.txt" "$(INSTALL_DIR)/requirements.txt"
	chmod +x "$(PDF_SERVICE)"
	chmod +x "$(INSTALL_DIR)/worker.sh"
	chmod +x "$(INSTALL_DIR)/print_label.py"

install-venv:
	mkdir -p "$(INSTALL_DIR)"
	cp "$(PROJECT_DIR)/requirements.txt" "$(INSTALL_DIR)/requirements.txt"
	python3 -m venv "$(VENV_DIR)"
	"$(VENV_PIP)" install -r "$(INSTALL_DIR)/requirements.txt"

undeploy:
	-launchctl bootout gui/$(UID) "$(PLIST_DST)" 2>/dev/null
	-rm -f "$(PLIST_DST)"
	-rm -f "$(PDF_SERVICE)"
	-rm -rf "$(INSTALL_DIR)"

reload: deploy

venv: install-venv
	@echo "Venv ready."
