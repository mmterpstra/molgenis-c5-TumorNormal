#MOLGENIS walltime=23:59:00 mem=15gb nodes=1 ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
#string samtoolsMod

#string mergeBamFilesBam
#string mergeBamFilesBai

#string markDuplicatesDir
#string markDuplicatesBam
#string markDuplicatesBai
#string markDuplicatesMetrics
#list reads3FqGz

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${markDuplicatesBam} \
 ${markDuplicatesBai} \
 ${markDuplicatesMetrics}

getFile ${mergeBamFilesBam}
getFile ${mergeBamFilesBai}

${stage} ${picardMod}
${stage} ${samtoolsMod}

${checkStage}

set -x
set -e

mkdir -p ${markDuplicatesDir}


# test for specified FqGz with UMIs if not present do default markduplicates else do UmiAwareMarkDuplicatesWithMateCigar
#if [ ${#reads3FqGz[0]} -eq 0 ];then
if [ $(samtools view ${mergeBamFilesBam} | head -n 10 | grep -c 'RX:') -eq 0 ]; then
	java -Xmx14g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar MarkDuplicates \
	 INPUT=${mergeBamFilesBam} \
	 OUTPUT=${markDuplicatesBam} \
	 CREATE_INDEX=true \
	 MAX_RECORDS_IN_RAM=4000000 \
	 TMP_DIR=${markDuplicatesDir} \
	 METRICS_FILE=${markDuplicatesMetrics}

else
	#umi aware
	java -Xmx14g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar UmiAwareMarkDuplicatesWithMateCigar \
         INPUT=${mergeBamFilesBam} \
         OUTPUT=${markDuplicatesBam} \
         CREATE_INDEX=true \
         MAX_RECORDS_IN_RAM=4000000 \
         TMP_DIR=${markDuplicatesDir} \
	 METRICS_FILE=${markDuplicatesMetrics} \
         UMI_METRICS_FILE=${markDuplicatesMetrics}.umi.log \
	 UMI_TAG_NAME="RX" \
	 MAX_EDIT_DISTANCE_TO_JOIN=1

fi
#REMOVE_DUPLICATES=true \?

putFile ${markDuplicatesBam}
putFile ${markDuplicatesBai}
putFile ${markDuplicatesMetrics}

echo "## "$(date)" ##  $0 Done "
