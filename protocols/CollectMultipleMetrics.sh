#MOLGENIS walltime=23:59:00 mem=5gb nodes=1 ppn=4

#string project



#string stage
#string checkStage
#string picardMod
#string RMod
#list reads2FqGz
#string collectMultipleMetricsDir
#string collectMultipleMetricsPrefix
#string onekgGenomeFasta
#string dbsnpVcf
#string targetsList
#string markDuplicatesBam
#string markDuplicatesBai

#alloutputsext
alloutputsexist \
 ${collectMultipleMetricsPrefix}.alignment_summary_metrics \
 ${collectMultipleMetricsPrefix}.quality_by_cycle_metrics \
 ${collectMultipleMetricsPrefix}.quality_by_cycle.pdf \
 ${collectMultipleMetricsPrefix}.quality_distribution_metrics \
 ${collectMultipleMetricsPrefix}.quality_distribution.pdf 
# ${collectMultipleMetricsPrefix}.insert_size_histogram.pdf \
# ${collectMultipleMetricsPrefix}.insert_size_metrics 
#

echo "## "$(date)" Start $0"

#echo  ${collectMultipleMetricsPrefix} 

getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}
getFile ${onekgGenomeFasta}
getFile ${dbsnpVcf}
getFile ${targetsList}

#load modules
${stage} ${picardMod}
${stage} ${RMod}
${checkStage}

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${collectMultipleMetricsDir}

insertSizeMetrics=""
if [ ${#reads2FqGz} -ne 0 ]; then
	insertSizeMetrics="PROGRAM=CollectInsertSizeMetrics"
fi
intervals=""
if [ ${#targetsList} -ne 0 ]; then 
	intervals="INTERVALS=${targetsList}"
fi

#Run Picard CollectAlignmentSummaryMetrics, CollectInsertSizeMetrics, QualityScoreDistribution and MeanQualityByCycle
#as of 2.10:
#CollectAlignmentSummaryMetrics, CollectInsertSizeMetrics, QualityScoreDistribution, 
#MeanQualityByCycle, CollectBaseDistributionByCycle, CollectGcBiasMetrics, RnaSeqMetrics, 
#CollectSequencingArtifactMetrics, CollectQualityYieldMetrics
java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CollectMultipleMetrics\
 I=${markDuplicatesBam} \
 O=${collectMultipleMetricsPrefix} \
 R=${onekgGenomeFasta} \
 PROGRAM=CollectAlignmentSummaryMetrics \
 PROGRAM=QualityScoreDistribution \
 PROGRAM=MeanQualityByCycle \
 $insertSizeMetrics \
 PROGRAM=CollectBaseDistributionByCycle \
 PROGRAM=CollectGcBiasMetrics \
 PROGRAM=CollectSequencingArtifactMetrics \
 PROGRAM=CollectQualityYieldMetrics \
 DB_SNP=${dbsnpVcf}  \
 $intervals \
 TMP_DIR=${collectMultipleMetricsDir}

#VALIDATION_STRINGENCY=LENIENT \

putFile  ${collectMultipleMetricsPrefix}.alignment_summary_metrics 
putFile ${collectMultipleMetricsPrefix}.quality_by_cycle_metrics 
putFile ${collectMultipleMetricsPrefix}.quality_by_cycle.pdf 
putFile ${collectMultipleMetricsPrefix}.quality_distribution_metrics 
putFile ${collectMultipleMetricsPrefix}.quality_distribution.pdf

if [ ${#reads2FqGz} -ne 0 ]; then
	putFile ${collectMultipleMetricsPrefix}.insert_size_histogram.pdf
	putFile ${collectMultipleMetricsPrefix}.insert_size_metrics
fi

echo "## "$(date)" ##  $0 Done "
