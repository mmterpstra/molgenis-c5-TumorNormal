#MOLGENIS walltime=23:59:00 mem=5gb nodes=1 ppn=4

#string project



#string stage
#string checkStage
#string picardMod
#string RMod
#string samtoolsMod
#string fgbioMod
#list reads2FqGz
#string collectDuplexMetricsDir
#string collectDuplexMetricsPrefix
#string onekgGenomeFasta
#string dbsnpVcf
#string targetsList
#string consensusBam
#string consensusBai
#string consensusDir

#alloutputsext
alloutputsexist \
 ${collectDuplexMetricsPrefix}.alignment_summary_metrics \
 ${collectDuplexMetricsPrefix}.quality_by_cycle_metrics \
 ${collectDuplexMetricsPrefix}.quality_distribution_metrics 

# ${collectMultipleMetricsPrefix}.quality_by_cycle.pdf \
# ${collectMultipleMetricsPrefix}.quality_distribution.pdf 
# ${collectMultipleMetricsPrefix}.insert_size_histogram.pdf \
# ${collectMultipleMetricsPrefix}.insert_size_metrics 
#


echo "## "$(date)" Start $0"

#echo  ${collectMultipleMetricsPrefix} 

getFile ${consensusBam}
#more important:${consensusBam}.grouped.bam
#getFile ${consensusBai}
getFile ${onekgGenomeFasta}
#getFile ${dbsnpVcf}
getFile ${targetsList}

#load modules	
${stage} ${RMod}
${stage} ${samtoolsMod}
${stage} ${picardMod}
${stage} ${fgbioMod}
${checkStage}

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${collectDuplexMetricsDir}

intervals=""
if [ ${#targetsList} -ne 0 ]; then 
	intervals="--intervals ${targetsList}"
fi

if [ `samtools view -c "${consensusBam}.grouped.bam"` == 0 ] ; then 
	"## INFO ## No reads skipping analysis"
	touch ${collectDuplexMetricsPrefix}.duplex_yield_metrics.txt
	touch ${collectDuplexMetricsPrefix}.duplex_qc.pdf
else 
	groupedbam="${consensusBam}.grouped.bam"
	
	if [ `samtools view -h "${consensusBam}.grouped.bam" | grep -Pc 'RX:Z:[ATCGN]+-'` == 0 ] ; then
		groupedbam="$(dirname "${consensusBam}.grouped.bam")"/"$(basename "${consensusBam}.grouped.bam" .grouped.bam).umifix.grouped.bam"
		samtools view -h "${consensusBam}.grouped.bam" | perl -wpe 's/RX:Z:[ATCGN]+/$&-AAAAAA/g' | samtools view -Sb> "${groupedbam}"
	fi		
	java -Xmx5g  -Djava.io.tmpdir="${consensusDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap \
	 -jar $EBROOTFGBIO/lib/fgbio-1.3.0.jar CollectDuplexSeqMetrics \
	 --input="${groupedbam}" \
	 --output="${collectDuplexMetricsPrefix}" \
	 $intervals
fi


putFile ${collectDuplexMetricsPrefix}.duplex_yield_metrics.txt
putFile ${collectDuplexMetricsPrefix}.duplex_qc.pdf    

echo "## "$(date)" ##  $0 Done "
