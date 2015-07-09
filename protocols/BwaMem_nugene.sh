#MOLGENIS nodes=1 ppn=8 mem=8gb walltime=10:00:00


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string bwaVersion
#string WORKDIR
#string resDir
#string toolDir
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string bwaAlignmentDir 
#string bwaSam
#string nTreads
#string reads1FqGz
#string reads2FqGz

echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${bwaSam}
 
#getFile functions

getFile ${genomeEnsembleAnnotationFile}

#Load modules
${stage} bwa/${bwaVersion}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${bwaAlignmentDir}


if [ ${#reads2FqGz} -eq 0 ]; then
	getFile ${reads1FqGz}
	bwa mem \
	 -M \
	 -t ${nTreads} \
	 ${onekgGenomeFastaIdxBase} \
	 ${reads1FqGz} \
	 > ${bwaSam}
else
	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
        bwa mem \
	 -M \
	 -t ${nTreads} \
	 ${onekgGenomeFastaIdxBase} \
	 ${reads1FqGz} \
	 ${reads2FqGz} \
	 > ${bwaSam}
fi

putFile ${bwaSam} 

echo "## "$(date)" ##  $0 Done "
