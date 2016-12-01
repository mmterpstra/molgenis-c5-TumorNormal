#MOLGENIS walltime=23:59:00 mem=8gb nodes=1 ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod

#string mergeBamFilesBam
#string mergeBamFilesBai

#string markDuplicatesDir
#string markDuplicatesBam
#string markDuplicatesBai
#string markDuplicatesMetrics


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${markDuplicatesBam} \
 ${markDuplicatesBai} \
 ${markDuplicatesMetrics}

getFile ${mergeBamFilesBam}
getFile ${mergeBamFilesBai}

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${markDuplicatesDir}

java -Xmx6g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar MarkDuplicates \
 INPUT=${mergeBamFilesBam} \
 OUTPUT=${markDuplicatesBam} \
 CREATE_INDEX=true \
 MAX_RECORDS_IN_RAM=4000000 \
 TMP_DIR=${markDuplicatesDir} \
 METRICS_FILE=${markDuplicatesMetrics}

#REMOVE_DUPLICATES=true \?

putFile ${markDuplicatesBam}
putFile ${markDuplicatesBai}
putFile ${markDuplicatesMetrics}

echo "## "$(date)" ##  $0 Done "
