#MOLGENIS nodes=1 ppn=8 mem=9gb walltime=10:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string bwaMod
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string bwaAlignmentDir 
#string bwaSam
#string nTreads
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${bwaSam}
 
#getFile functions

getFile ${onekgGenomeFasta}

#Load modules
${stage} ${bwaMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${bwaAlignmentDir}


if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	getFile ${reads1FqGz}
	bwa mem \
	 -t ${nTreads} \
	 ${onekgGenomeFastaIdxBase} \
	 ${reads1FqGz} \
	 > ${bwaSam}
else
	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
        bwa mem \
	 -t ${nTreads} \
	 ${onekgGenomeFastaIdxBase} \
	 ${reads1FqGz} \
	 ${reads2FqGz} \
	 > ${bwaSam}
fi

putFile ${bwaSam} 

echo "## "$(date)" ##  $0 Done "
