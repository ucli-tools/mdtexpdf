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
	$(INSTALL_NAME) convert example1.md -t "Test 1 Title" -a "Test Author" -d "yes" -f "© Example Name. All rights reserved. | example.com" --date-footer && \
	$(INSTALL_NAME) convert example2.md -t "Test 2 Title" -a "Test Author" -d "no" -f "© Example Name. All rights reserved. | example.com" --date-footer "YYYY-MM-DD" && \
	$(INSTALL_NAME) convert example3.md -t "Test 3 Title" -a "Test Author" -d "2000/01/02" -f "© Example Name. All rights reserved. | example.com" --date-footer "Month Day, Year" && \
	$(INSTALL_NAME) convert example4.md -t "Test 4 Title" -a "Test Author" -d "YYYY-MM-DD" -f "© Example Name. All rights reserved. | example.com" --toc && \
	$(INSTALL_NAME) convert example5.md -t "Test 5 Title" -a "Test Author" -d "YYYY-MM-DD" -f "© Example Name. All rights reserved. | example.com" --toc --toc-depth 2 && \
	$(INSTALL_NAME) convert example6.md -t "Test 6 Title" -a "Test Author" -d "YYYY-MM-DD" -f "© Example Name. All rights reserved. | example.com" --toc --toc-depth 3 && \
	cd .. && \
	$(INSTALL_NAME) convert test_numbering.md -t "Section Numbering Test" -a "Test Author" -d "YYYY-MM-DD" -f "© Example Name. All rights reserved." --no-numbers && \
	rm -f template.tex && \
	rm -f *.bak