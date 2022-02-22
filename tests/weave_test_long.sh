#!/bin/bash
set -e
set -x

probe=""

if [ $1 == "nugene" ] ; then
	probe="data/resource/probe.bed"
elif [ $1 == "nugrna" ] ; then
	probe="data/resource/probe.bed"
elif [ $1 == "iont" ] ; then
        probe="data/resource/probe.bed"
fi

perl -wpe 's!/home/travis/build/mmterpstra/molgenis-c5-TumorNormal/tests/data/raw/(head_40000_[12].fq.gz)!'"$PWD"'/data/raw/$1!g' $2 > "${2}_testpathfix.csv"


(
cat  $2_testpathfix.csv
for i in $(seq 1 250); do
	tail -n +2 $2 | perl -wpe 's/^/'"$1"'/;s/Here\,sample/Here,sample'"$1"'/g'
done)> samplesheet_long.csv


touch dummy.interval_list && \
	bash ../scripts/GenerateScripts.sh $1 samplesheet_long.csv exome dummy.interval_list $probe

bash .RunWorkFlowGeneration.sh &> workflow_generation.log || (tail -n 100 workflow_generation.log ; exit 1)

submitSh="$(tail -n 1 workflow_generation.log | cut -d\  -f 2)"
for i in  $(dirname "$submitSh")/*.sh; do
	>&2 echo  "## "$(date)" ## $0 ## checking $i"
	bash -n "$i"
done
