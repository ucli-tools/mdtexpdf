.PHONY: build publish upload

# Build the article in PDF LaTeX
build:
	@dir_name=$$(basename $$(pwd)); \
	target_file="$$dir_name.md"; \
	if [ -f "$$target_file" ]; then \
		echo "Building $$target_file with metadata"; \
		mdtexpdf convert "$$target_file" --read-metadata; \
	else \
		echo "No target file $$target_file found in $$(pwd)"; \
	fi

# Publish the article
publish:
	@dir_name=$$(basename $$(pwd)); \
	target_file="$$dir_name.md"; \
	if [ -f "$$target_file" ]; then \
		echo "Publishing $$target_file"; \
		bash ../lib/publish_article.sh .; \
	else \
		echo "No target file $$target_file found in $$(pwd)"; \
	fi

# Complete workflow for single article: build + publish (publish handles PDF transfer)
upload: build publish
	@echo "Single article upload complete: $(basename $(pwd))"
