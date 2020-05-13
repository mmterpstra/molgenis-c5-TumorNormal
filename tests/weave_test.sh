#!/bin/bash
set -e
set -o pipefail
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
export SAMPLESHEETFOLDER="./"
touch dummy.interval_list && bash ../GenerateScripts.sh $1 "${2}_testpathfix.csv" exome dummy.interval_list $probe
bash .RunWorkFlowGeneration.sh &> workflow_generation.log || (tail -n 100 workflow_generation.log ; exit 1)
)&>/dev/stdout	| tail -n 30

submitSh="$(tail -n 1 workflow_generation.log | cut -d\  -f 2)"

for i in  $(dirname "$submitSh")/*.sh; do
	>&2 echo  "## "$(date)" ## $0 ## checking $i"
	bash -n "$i"
done

