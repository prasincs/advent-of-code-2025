.PHONY: help build test run fmt fmt-check check clean install download

help: ## Show this help message
	@echo "Advent of Code 2025 - Zig Project"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the project
	zig build

test: ## Run all tests
	zig build test

run: ## Run a solution (usage: make run DAY=1 PART=1 SAMPLE=sample1.txt)
	@if [ -z "$(DAY)" ]; then \
		echo "Error: DAY is required. Usage: make run DAY=1"; \
		exit 1; \
	fi
	@CMD="zig build run -- run --day $(DAY)"; \
	if [ -n "$(PART)" ]; then CMD="$$CMD --part $(PART)"; fi; \
	if [ -n "$(SAMPLE)" ]; then CMD="$$CMD --sample $(SAMPLE)"; fi; \
	echo "Running: $$CMD"; \
	$$CMD

download: ## Download puzzle input (usage: make download DAY=1)
	@if [ -z "$(DAY)" ]; then \
		echo "Error: DAY is required. Usage: make download DAY=1"; \
		exit 1; \
	fi
	zig build run -- download --day $(DAY)

fmt: ## Format all source files
	zig build fmt-fix

fmt-check: ## Check formatting without modifying files
	zig build fmt

check: ## Run all quality checks (fmt + test)
	zig build check

clean: ## Clean build artifacts
	rm -rf zig-cache zig-out .zig-cache

install: ## Install dependencies (check for curl)
	@command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed. Please install curl."; exit 1; }
	@command -v zig >/dev/null 2>&1 || { echo "Error: zig is required but not installed. Please install zig."; exit 1; }
	@echo "✓ All dependencies are installed"
	@echo "  - zig: $$(zig version)"
	@echo "  - curl: $$(curl --version | head -n1)"
