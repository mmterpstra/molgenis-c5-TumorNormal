#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project
#string projectDir

#string multiqcMod
#string stage
#string checkStage


#string projectMultiQcHtml

alloutputsexist \
 ${projectMultiQcHtml} \

echo "## "$(date)" Start $0"

#load modules
${stage} ${multiqcMod}

${checkStage}

set -x
set -e


cd ${projectDir}
multiqc ./

putFile ${projectMultiQcHtml}

echo "## "$(date)" Done $0"

