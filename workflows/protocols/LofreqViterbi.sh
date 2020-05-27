#MOLGENIS nodes=1 ppn=2 mem=6gb walltime=47:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string lofreqMod
#string samtoolsMod
#string picardMod
#string onekgGenomeFasta
#string targetsList
#string cosmicVcf
#string dbsnpVcf

#string bqsrBam
#string bqsrBai
#string viterbiDir
#string viterbiBam
#string viterbiBai


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${viterbiBam} \
 ${viterbiBai}

${stage} ${samtoolsMod} ${lofreqMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${bqsrBam}
getFile ${bqsrBai}
getFile ${cosmicVcf}
getFile ${dbsnpVcf}

set -x
set -e

mkdir -p ${viterbiDir}

#ideally this should be done on the normal/tumor at the same time
#due to design constraints here is one at a time approach...

lofreq viterbi --ref ${onekgGenomeFasta} ${bqsrBam} | samtools sort - > ${viterbiBam}
samtools index ${viterbiBam}

putFile ${viterbiBam}
putFile ${viterbiBai}


echo "## "$(date)" ##  $0 Done "
