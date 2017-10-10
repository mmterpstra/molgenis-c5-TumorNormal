#!/bin/bash
set -e
set -x

probe=""

if [ $1 == "nugene" ] ; then
	probe="data/resource/probe.bed"
elif [ $1 == "nugrna" ] ; then
	probe="data/resource/probe.bed"
fi
(
cat  $2
for i in $(seq 1 250); do
	tail -n +2 $2
done)> samplesheet_long.csv
touch dummy.interval_list && bash ../GenerateScripts2.sh $1 samplesheet_long.csv exome dummy.interval_list $probe
bash .RunWorkFlowGeneration.sh
for i in  /home/travis/projects/exome/jobs/*.sh; do
	>&2 echo  "## "$(date)" ## $0 ## checking $i"
	bash -n "$i"
done
