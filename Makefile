SHELL := /bin/bash


all-tests := $(addsuffix .test, $(basename $(wildcard test/*.test-in)))

test : $(all-tests)

%.test : %.test-in
	bash $< >$@ 2>$@.err || exit 1 

clean-test := (addsuffix .test, $(basename $(wildcard test/*.test test/*err)))

clean : rmtests

rmtests : $(all-tests)
	rm -v $(all-tests)

#	for test in $(ls test/*.sh); do echo $$test && bash $$test > $${test}.	test|| exit 1;  done

