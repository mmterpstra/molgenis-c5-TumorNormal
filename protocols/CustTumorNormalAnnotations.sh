#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#Parameter mapping
#string stage
#string checkStage
#string vcfToolsMod

#string annotatorDir
#string project
#string annotVcf
#string controlSampleName
#string custAnnotVcf
#string normalAnnotPl

#Check if output exists
alloutputsexist \
${custAnnotVcf}

echo ${annotatorDir} ${project} ${annotVcf}

getFile ${annotVcf}

${stage} ${vcfToolsMod}
${checkStage}

set -x
set -e

perl ${normalAnnotPl} \
 ${controlSampleName} \
 ${annotVcf} \
 >${custAnnotVcf}

putFile ${custAnnotVcf}
