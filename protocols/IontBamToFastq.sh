#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string picardMod
#string projectDir
#string bamFiles
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal
#string sampleName

echo -e "test ${reads1FqGz} ${reads2FqGz} 1: "

${stage} ${picardMod}
${checkStage}

set -x
set -e

echo "## "$(date)" ##  $0 Started "
	
if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	inputs=$(printf ' I=%s' $(echo ${bamFiles}| tr ';' '\n' ))
	
	java -Xmx6g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar MergeSamFiles \
	 $inputs \
	 USE_THREADING=true \
	 MAX_RECORDS_IN_RAM=6000000 \
	 OUTPUT=/dev/stdout | \
	java -Xmx6g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar SamToFastq \
	 I=/dev/stdin \
	 F=${reads1FqGz} \
	 CREATE_MD5_FILE=true
	
	putFile ${reads1FqGz}
	#putFile ${reads2FqGz}

else
	echo "Not implemented"
	exit 1
fi

echo "## "$(date)" ##  $0 Done "
