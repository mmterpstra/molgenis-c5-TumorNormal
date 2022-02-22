#MOLGENIS walltime=23:59:00 mem=5gb nodes=1 ppn=4

#string project



#string stage
#string checkStage
#string picardMod
#string RMod
#string samtoolsMod
#list reads2FqGz
#string collectWGSMetricsDir
#string collectWGSMetricsPrefix
#string onekgGenomeFasta
#string dbsnpVcf
#string targetsList
#string markDuplicatesBam
#string markDuplicatesBai

#alloutputsext
alloutputsexist \
 ${collectWGSMetricsPrefix}.raw_wgs_metrics.tsv \
 ${collectWGSMetricsPrefix}.wgs_metrics.tsv \

echo "## "$(date)" Start $0"

#echo  ${collectWGSMetricsDir} 

getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}
getFile ${onekgGenomeFasta}
getFile ${targetsList}

#load modules
${stage} ${RMod}
${stage} ${samtoolsMod}
${stage} ${picardMod}

${checkStage}

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${collectWGSMetricsDir}


if [ `samtools view -c ${markDuplicatesBam}` == 0 ] ; then 
	"## INFO ## No reads skipping analysis"
	touch ${collectWGSMetricsPrefix}.raw_wgs_metrics.tsv
	touch ${collectWGSMetricsPrefix}.wgs_metrics.tsv
else 

	java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CollectRawWgsMetrics \
	 I=${markDuplicatesBam} \
	 O=${collectWGSMetricsPrefix}.raw_wgs_metrics.tsv \
	 R=${onekgGenomeFasta}
	 
	java -jar -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar CollectWgsMetrics \
	 I=${markDuplicatesBam} \
	 O=${collectWGSMetricsPrefix}.wgs_metrics.tsv \
	 R=${onekgGenomeFasta} \
	 INCLUDE_BQ_HISTOGRAM=true

fi

#VALIDATION_STRINGENCY=LENIENT \

putFile ${collectWGSMetricsPrefix}.raw_wgs_metrics.tsv
putFile ${collectWGSMetricsPrefix}.wgs_metrics.tsv

echo "## "$(date)" ##  $0 Done "
