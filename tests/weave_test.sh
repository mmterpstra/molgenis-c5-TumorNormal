#!/bin/bash
set -e
set -x

touch dummy.interval_list && bash ../GenerateScripts2.sh $1 ../samplesheet.csv exome dummy.interval_list
bash .RunWorkFlowGeneration.sh
