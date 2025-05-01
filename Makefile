# Get the script name dynamically based on sole script in repo
SCRIPT_NAME := $(wildcard *.sh)
INSTALL_NAME := $(basename $(SCRIPT_NAME))

build:
	bash $(SCRIPT_NAME) install

rebuild:
	$(INSTALL_NAME) uninstall
	bash $(SCRIPT_NAME) install
	
delete:
	$(INSTALL_NAME) uninstall