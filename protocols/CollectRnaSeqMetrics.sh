#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod

#string markDuplicatesBam
#string markDuplicatesBai
#string collectRnaSeqMetricsDir
#string collectRnaSeqMetrics
#string collectRnaSeqMetricsChart
#string genesRefFlat
#string rRnaIntervalList
#string onekgGenomeFasta


alloutputsexist \
 ${collectRnaSeqMetrics} \
 ${collectRnaSeqMetricsChart}

getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${collectRnaSeqMetricsDir}

echo "## "$(date)" ##  $0 Started "

java -Xmx4g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar CollectRnaSeqMetrics \
 INPUT=${markDuplicatesBam} \
 OUTPUT=${collectRnaSeqMetrics} \
 CHART_OUTPUT=${collectRnaSeqMetricsChart} \
 METRIC_ACCUMULATION_LEVEL=SAMPLE \
 METRIC_ACCUMULATION_LEVEL=READ_GROUP \
 REFERENCE_SEQUENCE=${onekgGenomeFasta} \
 REF_FLAT=${genesRefFlat} \
 RIBOSOMAL_INTERVALS=${rRnaIntervalList} \
 STRAND_SPECIFICITY=NONE \
 TMP_DIR=${collectRnaSeqMetricsDir} \
 

putFile ${collectRnaSeqMetrics}
putFile ${collectRnaSeqMetricsChart}

echo "## "$(date)" ##  $0 Done "
