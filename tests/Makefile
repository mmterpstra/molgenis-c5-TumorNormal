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
test-wfremap:
	bash test_wfremap.sh
test-mlcompute:
	ml Molgenis-Compute && molgenis_compute.sh
test-protocolsyntax:
	bash protocol_test.sh
test-headerfootersyntax:
	bash headerfooter_test.sh
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
test-weave-grch38:
	bash weave_test.sh exomehuman38 ../samplesheet.csv
test-weave-umi:
	bash weave_test.sh umi ../samplesheet.csv
#removed test-weave-iont  test-weave-nugene test-weave-nuginc test-weave-withpoly test-weave-nugrna test-weave-lexo from test all

test-all: test-java test-perl test-bash test-python test-wfdups test-wfremap test-mlcompute test-protocolsyntax test-headerfootersyntax test-weave-exome test-weave-rna test-weave-withpoly test-weave-nuginc test-weave-umi

test: test-all
