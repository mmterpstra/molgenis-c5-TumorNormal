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
	bash weave_test.sh exome ../samplesheet.csv
test-weave-rna:
	bash weave_test.sh rna ../samplesheet.csv
test-weave-withpoly:
	bash weave_test.sh withpoly ../samplesheet.csv
test-weave-iont:
	bash weave_test.sh iont ../samplesheet.csv
test-weave-nugene:
	bash weave_test.sh nugene ../samplesheet.csv
test-weave-nuginc:
	bash weave_test.sh nuginc ../samplesheet.csv
test-weave-nugrna:
	bash weave_test.sh nugrna ../samplesheet.csv
test-weave-exome-long:
	bash weave_test_long.sh exome ../samplesheet.csv
test-weave-lexo:
	bash weave_test.sh lexo ../samplesheet.csv

	
test-all: test-java test-perl test-bash test-python test-wfdups test-mlcompute test-weave-exome test-weave-rna test-weave-withpoly test-weave-iont test-weave-nugene test-weave-nuginc test-weave-nugrna test-weave-lexo
test: test-all
