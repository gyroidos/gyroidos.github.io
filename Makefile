.PHONY: help
help:
	@echo "Available targets:"
	@echo "  install		- Installs the required dependencies"
	@echo "  run			- Run jekyll with live reload"
	@echo "  build			- Build the static web page"

.PHONY: install
install:
	bundle install

.PHONY: run
run:
	bundle exec jekyll serve

.PHONY: build
build:
	bundle exec jekyll build