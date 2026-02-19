.PHONY: help build rebuild delete test test-unit test-all test-examples lint ci-local docker docker-build docker-push clean

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

build: ## Install mdtexpdf locally
	@bash mdtexpdf.sh install

rebuild: ## Reinstall mdtexpdf (uninstall + install)
	@mdtexpdf uninstall
	@bash mdtexpdf.sh install

delete: ## Uninstall mdtexpdf
	@mdtexpdf uninstall

test: test-unit ## Run tests (alias for test-unit)

test-unit: ## Run unit tests
	@./tests/run_tests.sh

test-all: ## Run full CI suite (lint + tests)
	@bash scripts/test-all.sh

test-examples: ## Run example document builds (requires install)
	@bash scripts/test-examples.sh

lint: ## Run shellcheck linter
	@shellcheck -x mdtexpdf.sh lib/*.sh

ci-local: ## Run CI in a local Docker container
	@bash scripts/ci-local.sh

docker-build: ## Build Docker image
	@bash scripts/docker-build.sh

docker-push: ## Push Docker image to Docker Hub
	@bash scripts/docker-push.sh

docker: docker-build ## Build Docker image (alias)

clean: ## Clean test outputs and temp files
	@bash scripts/clean.sh
