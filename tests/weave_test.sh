#!/bin/bash
set -e
set -x

probe=""

if [ $1 == "nugene" ] ; then
	probe="data/resource/probe.bed"
elif [ $1 == "nugrna" ] ; then
	probe="data/resource/probe.bed"
fi
touch dummy.interval_list && bash ../GenerateScripts2.sh $1 ../samplesheet.csv exome dummy.interval_list $probe
bash .RunWorkFlowGeneration.sh
for i in  /home/travis/projects/exome/jobs/*.sh; do
	>&2 echo  "## "$(date)" ## $0 ## checking $i"
	bash -n "$i"
done
