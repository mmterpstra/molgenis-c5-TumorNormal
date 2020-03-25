SHELL := /bin/bash

test-all:
	$(MAKE) -C tests/ $@
test: test-all
