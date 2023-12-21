#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#string project

#Parameter mapping
#string stage
#string checkStage
#string vcfToolsMod
#string pipelineUtilMod

#string annotatorDir
#string annotVcf
#list controlSampleName
#string custAnnotVcf
#string normalAnnotPl

#Check if output exists
alloutputsexist \
${custAnnotVcf}

echo ${annotatorDir} ${project} ${annotVcf}

getFile ${annotVcf}

#${stage} ${vcfToolsMod}
${stage} ${pipelineUtilMod}
${checkStage}

set -x
set -e

perl $EBROOTPIPELINEMINUTIL/bin/${normalAnnotPl} \
 ${controlSampleName[0]} \
 ${annotVcf} \
 >${custAnnotVcf}

putFile ${custAnnotVcf}

echo "## "$(date)" ##  $0 Done "

