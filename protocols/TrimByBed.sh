#MOLGENIS walltime=23:59:00 mem=6gb nodes=1 ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
#string sampleName
#string bwaSam
#string pipelineUtilMod
#string probeBed
#string trimByBedDir
#string trimByBedBam
#string trimByBedBai


alloutputsexist \
 ${trimByBedBam} \
 ${trimByBedBai}

echo "## "$(date)" ##  $0 Started "

getFile ${bwaSam}

${stage} ${pipelineUtilMod}
${checkStage}

set -x
set -e
set -o pipefail

mkdir -p ${trimByBedDir}

echo "## "$(date)" Start $0"


perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl \
 -s ${bwaSam} \
 -b ${probeBed} \
 -o $(dirname ${trimByBedBam})/$(basename ${trimByBedBam} .bam).out \
 -n $(dirname ${trimByBedBam})/$(basename ${trimByBedBam} .bam) \
 &>/dev/stdout | tail -n 1000


putFile ${trimByBedBam}
putFile ${trimByBedBam}


echo "## "$(date)" ##  $0 Done "
