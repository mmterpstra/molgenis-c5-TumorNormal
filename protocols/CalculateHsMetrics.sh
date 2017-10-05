#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project



#string stage
#string checkStage
#string picardOldMod
#string RMod
#string onekgGenomeFasta
#string markDuplicatesBam
#string markDuplicatesBai

#string calculateHsMetricsDir
#string calculateHsMetricsLog
#string calculateHsMetricsPerTargetCov
#string targetsList

#alloutputsext
alloutputsexist \
 ${calculateHsMetricsLog} \
 ${calculateHsMetricsPerTargetCov}

echo "## "$(date)" Start $0"

getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}
getFile ${onekgGenomeFasta}
getFile ${targetsList}


#load modules
${stage} ${picardOldMod}
${stage} ${RMod}
${checkStage}

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${calculateHsMetricsDir}


#Run Picard
java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CalculateHsMetrics\
 I=${markDuplicatesBam} \
 O=${calculateHsMetricsLog} \
 R=${onekgGenomeFasta} \
 BAIT_INTERVALS=${targetsList} \
 TARGET_INTERVALS=${targetsList} \
 PER_TARGET_COVERAGE=${calculateHsMetricsPerTargetCov} \
 METRIC_ACCUMULATION_LEVEL=ALL_READS \
 TMP_DIR=${calculateHsMetricsDir}

rm ${calculateHsMetricsLog} -v

java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CalculateHsMetrics\
 I=${markDuplicatesBam} \
 O=${calculateHsMetricsLog} \
 R=${onekgGenomeFasta} \
 BAIT_INTERVALS=${targetsList} \
 TARGET_INTERVALS=${targetsList} \
 METRIC_ACCUMULATION_LEVEL=SAMPLE \
 TMP_DIR=${calculateHsMetricsDir}


#VALIDATION_STRINGENCY=LENIENT \


putFile ${calculateHsMetricsLog}
putFile ${calculateHsMetricsPerTargetCov}

echo "## "$(date)" ##  $0 Done "
