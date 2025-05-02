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

test:
	cd examples/ && \
	$(INSTALL_NAME) convert example1.md -t "Test 1 Title" -a "Test Author" -d "2000/01/02" -f "Copyright Test Line" && \
	$(INSTALL_NAME) convert example2.md -t "Test 2 Title" -a "Test Author" -d "2000/01/02" -f "Copyright Test Line" && \
	rm -f template.tex && \
	rm -f *.bak