#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project



#string stage
#string checkStage
#string picardMod
#string RMod
#string onekgGenomeFasta
#string markDuplicatesBam
#string markDuplicatesBai

#string collectHsMetricsDir
#string collectHsMetricsLog
#string collectHsMetricsPerTargetCov
#string targetsList

#alloutputsext
alloutputsexist \
 ${collectHsMetricsLog} \
 ${collectHsMetricsPerTargetCov}

echo "## "$(date)" Start $0"

getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}
getFile ${onekgGenomeFasta}
getFile ${targetsList}


#load modules
${stage} ${picardMod}
${checkStage}

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${collectHsMetricsDir}


#Run Picard
java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CollectHsMetrics\
 I=${markDuplicatesBam} \
 O=${collectHsMetricsLog} \
 R=${onekgGenomeFasta} \
 BAIT_INTERVALS=${targetsList} \
 TARGET_INTERVALS=${targetsList} \
 PER_TARGET_COVERAGE=${collectHsMetricsPerTargetCov} \
 METRIC_ACCUMULATION_LEVEL=ALL_READS \
 TMP_DIR=${collectHsMetricsDir}

#Just to be sure it does not complain
rm ${collectHsMetricsLog} -v

java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CollectHsMetrics\
 I=${markDuplicatesBam} \
 O=${collectHsMetricsLog} \
 R=${onekgGenomeFasta} \
 BAIT_INTERVALS=${targetsList} \
 TARGET_INTERVALS=${targetsList} \
 METRIC_ACCUMULATION_LEVEL=SAMPLE \
 TMP_DIR=${collectHsMetricsDir}


#VALIDATION_STRINGENCY=LENIENT \


putFile ${collectHsMetricsLog}
putFile ${collectHsMetricsPerTargetCov}

echo "## "$(date)" ##  $0 Done "
