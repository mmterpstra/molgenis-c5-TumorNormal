#!/bin/bash
set -e
set -x

touch dummy.interval_list && bash ../GenerateScripts2.sh $1 ../samplesheet.csv exome dummy.interval_list
bash .RunWorkFlowGeneration.sh
for i in  /home/travis/projects/exome/jobs/*.sh; do
	>&2 echo  "## "$(date)" ## $0 ## checking $i"
	bash -n "$i"
done
