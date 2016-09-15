SHELL := /bin/bash

all-tests := $(addsuffix .test, $(basename $(wildcard test/*.test-in)))

test : $(all-tests)

%.test : %.test-in
	set -e; set -o pipefail; bash $< | tee $@

clean-tests := $(wildcard test/*.test)

clean : rmtests

rmtests :
	rm -v $(wildcard test/*.test)

#	for test in $(ls test/*.sh); do echo $$test && bash $$test > $${test}.	test|| exit 1;  done

