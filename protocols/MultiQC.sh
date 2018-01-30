#MOLGENIS walltime=23:59:00 mem=8gb nodes=1 ppn=1

#string project
#string projectDir

#string multiqcMod
#string stage
#string checkStage


#string multiQcHtml

alloutputsexist \
 ${multiQcHtml} \

echo "## "$(date)" Start $0"

#load modules
${stage} ${multiqcMod}

${checkStage}

set -x
set -e

#bracket execution is safer
(
	cd ${projectDir}
	
	multiqc --force ./
)

putFile ${multiQcHtml}

echo "## "$(date)" Done $0"

