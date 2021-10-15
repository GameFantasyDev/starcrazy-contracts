SHELL := /bin/bash
MAKEFLAGS += --no-print-directory

.PHONY: all
all: build

include makefiles/*.mk

.PHONY: build
build: build-sol ## build project

.PHONY: clean
clean: clean-build-sol ## clean

.PHONY: help
help: help-address
