#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project



#string stage
#string checkStage

#string fastqcMod
#string bwaMod
#string picardMod
#string RMod
#string gatkMod
#string snpEffMod
#string varScanMod
#string samtoolsMod
#string vcfToolsMod
#string pipelineUtilMod
#string tableToXlsxMod
#string digiRgMod
#string bbmapMod


#list reads2FqGz
#string collectMultipleMetricsDir
#string collectMultipleMetricsPrefix
#string onekgGenomeFasta
#string markDuplicatesBam
#string markDuplicatesBai

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

#getFile ${markDuplicatesBam}
#getFile ${markDuplicatesBai}
#getFile ${onekgGenomeFasta}




#load modules
${stage} ${fastqcMod}
${stage} ${bwaMod}
${stage} ${picardMod}
${stage} ${RMod}
${stage} ${gatkMod}
${stage} ${snpEffMod}
${stage} ${varScanMod}
${stage} ${samtoolsMod}
${stage} ${vcfToolsMod}
${stage} ${pipelineUtilMod}
${stage} ${tableToXlsxMod}
${stage} ${digiRgMod}
${stage} ${bbmapMod}

${checkStage}



${checkStage} > 

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${QcMarkdownDir}





#insertSizeMetrics=""
#if [ ${#reads2FqGz} -ne 0 ]; then
#	insertSizeMetrics="PROGRAM=CollectInsertSizeMetrics"
#fi

#Run Picard CollectAlignmentSummaryMetrics, CollectInsertSizeMetrics, QualityScoreDistribution and MeanQualityByCycle
#java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CollectMultipleMetrics\
# I=${markDuplicatesBam} \
# O=${collectMultipleMetricsPrefix} \
# R=${onekgGenomeFasta} \
# PROGRAM=CollectAlignmentSummaryMetrics \
# PROGRAM=QualityScoreDistribution \
# PROGRAM=MeanQualityByCycle \
# $insertSizeMetrics \
# TMP_DIR=${collectMultipleMetricsDir}

#VALIDATION_STRINGENCY=LENIENT \

#putFile  ${collectMultipleMetricsPrefix}.alignment_summary_metrics 
#putFile ${collectMultipleMetricsPrefix}.quality_by_cycle_metrics 
#putFile ${collectMultipleMetricsPrefix}.quality_by_cycle.pdf 
#putFile ${collectMultipleMetricsPrefix}.quality_distribution_metrics 
#putFile ${collectMultipleMetricsPrefix}.quality_distribution.pdf

#if [ ${#reads2FqGz} -ne 0 ]; then
#	putFile ${collectMultipleMetricsPrefix}.insert_size_histogram.pdf
#	putFile ${collectMultipleMetricsPrefix}.insert_size_metrics 
#fi

echo "## "$(date)" ##  $0 Done "
