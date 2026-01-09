# Copyright The KCL Authors. All rights reserved.

PROJECT_NAME = kcl
PWD:=$(shell pwd)

# ----------------
# Build
# ----------------

.PHONY: build
build: ## Run the build script (scripts/build.sh)
	${PWD}/scripts/build.sh

.PHONY: build-wasm
build-wasm: ## Build for WASM
	RUSTFLAGS="-Cpanic=abort -Cllvm-args=-wasm-use-legacy-eh=false" cargo build --target=wasm32-wasip1 --release

.PHONY: build-lsp
build-lsp: ## Build the LSP 
	cargo build --release --manifest-path crates/tools/src/LSP/Cargo.toml

.PHONY: build-cli
build-cli: ## Build the CLI 
	cargo build --release --manifest-path crates/cli/Cargo.toml

.PHONY: release
release: ## Run the release script (scripts/release.sh)
	${PWD}/scripts/release.sh

.PHONY: check
check: ## Cargo check all
	cargo check -r --all

.PHONY: fmt
fmt: ## Cargo fmt all 
	cargo fmt --all

.PHONY: lint
lint: ## Cargo clippy all packages 
	cargo clippy

.PHONY: lint-all
lint-all: ## Cargo clippy all packages (+workspace, +all_features, +benches, +examples, +tests)
	cargo clippy --workspace --all-features --benches --examples --tests

.PHONY: fix
fix: ## Cargo clippy --fix all packages 
	cargo clippy --fix --allow-dirty

gen-runtime-api: ## Generate runtime libraries when the runtime code is changed
	make -C crates/runtime gen-api-spec
	make fmt

install-rustc-wasm-wasi: ## Install the wasm-wasi target
	rustup target add wasm32-wasip1

install-test-deps: ## Ensure uv dependencies are synced
	uv sync

# ------------------------
# Tests
# ------------------------

test: ## Unit tests without code cov
	cargo test --workspace -r -- --nocapture

test-runtime: ## Test runtime libaries using python functions
	uv run pytest tests/runtime -vv || { echo 'runtime test failed' ; exit 1; }

test-grammar: ## E2E grammar tests with the fast evaluator
	PATH="${PWD}/target/release:${PWD}/target/debug:${PATH}" uv run pytest tests/grammar -n 5

help: ## Display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
