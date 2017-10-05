SHELL := /bin/bash
test-java:
	java -version
test-perl:
	perl --version
test-bash:
	bash --version
test-python:
	python --version
test-wfdups:
	bash test_wfdups.sh	
test-mlcompute:
	ml Molgenis-Compute && molgenis_compute.sh
test-weave-exome:
	bash weave_test.sh exome
test-weave-rna:
	bash weave_test.sh rna
test-weave-withpoly:
	bash weave_test.sh withpoly
test-weave-iont:
	bash weave_test.sh iont
test-weave-nugene:
	bash weave_test.sh nugene
test-weave-nuginc:
	bash weave_test.sh nuginc
test-weave-nugrna:
	bash weave_test.sh nugrna
	
test-all: test-java test-perl test-bash test-python test-wfdups test-mlcompute test-weave-exome test-weave-rna test-weave-withpoly test-weave-iont test-weave-nugene test-weave-nuginc test-weave-nugrna
test: test-all
