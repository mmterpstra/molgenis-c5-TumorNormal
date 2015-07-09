#MOLGENIS walltime=23:59:00 mem=6gb nodes=1 ppn=4

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir

#string picardVersion

#string MergeBamFilesBam
#string MergeBamFilesBai

#string markDuplicatesDir
#string markDuplicatesBam
#string markDuplicatesBai
#string markDuplicatesMetrics


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${markDuplicatesBam} \
 ${markDuplicatesBai} \
 ${markDuplicatesMetrics}

getFile ${MergeBamFilesBam}
getFile ${MergeBamFilesBai}

${stage} picard-tools/${picardVersion}
${checkStage}

set -x
set -e

mkdir -p ${markDuplicatesDir}

java -Xmx6g -XX:ParallelGCThreads=4 -jar $PICARD_HOME/MarkDuplicates.jar \
 INPUT=${MergeBamFilesBam} \
 OUTPUT=${markDuplicatesBam} \
 CREATE_INDEX=true \
 MAX_RECORDS_IN_RAM=4000000 \
 TMP_DIR=${markDuplicatesDir} \
 METRICS_FILE=${markDuplicatesMetrics}

#REMOVE_DUPLICATES=true \?

putFile ${markDuplicatesBam}
putFile ${markDuplicatesBai}
putFile ${markDuplicatesMetrics}

if [ ! -z "$PBS_JOBID" ]; then
	echo "## "$(date)" Collecting PBS job statistics"
	qstat -f $PBS_JOBID
fi

echo "## "$(date)" ##  $0 Done "
