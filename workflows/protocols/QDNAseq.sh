#MOLGENIS nodes=1 ppn=1 mem=10gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string onekgGenomeFasta
#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai
#string pipelineUtilMod
#string qdnaseqDir
#string qdnaseqPdf
#string qdnaseqSeg
#string qdnaseq1000kbpBins
#string qdnaseq100kbpBins
#string qdnaseq200kbpBins
#string qdnaseq5000kbpBins
#string qdnaseq500kbpBins
#string qdnaseq50kbpBins
#string qdnaseq1000kbpBins
#string qdnaseqPdf

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
	${qdnaseqPdf} ${qdnaseqSeg} ${qdnaseqDir}/$(basename $bins .Rds)/$cleanbam

set -x
set -e

${stage} ${pipelineUtilMod} 
${checkStage}

mkdir -p ${qdnaseqDir}

for bins in ${qdnaseq1000kbpBins} \
	 ${qdnaseq100kbpBins} \
	 ${qdnaseq200kbpBins} \
	 ${qdnaseq5000kbpBins} \
	 ${qdnaseq500kbpBins} \
	 ${qdnaseq50kbpBins} \
	 ${qdnaseq1000kbpBins}
do 
	getFile ${bins}
	cleanbam=$(echo $(basename "${indelRealignmentBam}") | perl -wpe 's! \-\.!_!g; s/_bam$/.bam/g' )
	
	mkdir -p ${qdnaseqDir}/$(basename $bins .Rds)/
	#$cleanbai?
	ln -s ${indelRealignmentBam} ${qdnaseqDir}/$(basename $bins .Rds)/$cleanbam
	putFile ${qdnaseqDir}/$(basename $bins .Rds)/$cleanbam
	runqDNAseq.Rscript $bins $cleanbam ${qdnaseqDir}/$(basename $bins .Rds)/$(basename $cleanbam .bam).pdf
	
	putFile ${qdnaseqDir}/$(basename $bins .Rds)/$(basename $cleanbam .bam).pdf
	putFile ${qdnaseqDir}/$(basename $bins .Rds)/$(basename $cleanbam .bam).seg
	putFile ${qdnaseqDir}/$(basename $bins .Rds)/$(basename $cleanbam .bam).vcf 
done


echo "## "$(date)" ##  $0 Done "
