#MOLGENIS walltime=23:59:00 mem=12gb nodes=1 ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
#string fgbioMod
#string samtoolsMod
#string reads3FqGzOriginal
#string bwaSam
#string onekgGenomeFasta
#string revertSamAddOrReplaceReadGroupsBam
#string mergeBamAlignmentDir
#string mergeBamAlignmentBam
#string mergeBamAlignmentBai

alloutputsexist \
 ${mergeBamAlignmentBam} ${mergeBamAlignmentBai} 
echo "## "$(date)" ##  $0 Started "

getFile ${bwaSam} ${revertSamAddOrReplaceReadGroupsBam}

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${mergeBamAlignmentDir}

echo "## "$(date)" Start $0"

#add umis if present
if [ ${#reads3FqGzOriginal} -eq 0 ]; then
	echo "No umis here"

BAMTOPROCESS="${revertSamAddOrReplaceReadGroupsBam}"

else
	ml ${fgbioMod}
	#this piece of code reads the umis in memory so more mem as the reads3 file gets bigger
	java -Xmx16g  -Djava.io.tmpdir="${mergeBamAlignmentDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTFGBIO/fgbio.jar AnnotateBamWithUmis \
	 --input "${revertSamAddOrReplaceReadGroupsBam}" \
	 --fastq ${reads3FqGzOriginal} \
	 --output "${mergeBamAlignmentBam}.revertsam.umi.bam" 

	BAMTOPROCESS="${mergeBamAlignmentBam}.revertsam.umi.bam"
fi

java -Djava.io.tmpdir="${mergeBamAlignmentDir}" -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar MergeBamAlignment \
 ALIGNED="${bwaSam}" UNMAPPED="${BAMTOPROCESS}" O="/dev/stdout" \
 R="${onekgGenomeFasta}" \
 SORT_ORDER=coordinate \
 ADD_MATE_CIGAR=true MAX_INSERTIONS_OR_DELETIONS=-1 \
 PRIMARY_ALIGNMENT_STRATEGY=MostDistant \
 UNMAP_CONTAMINANT_READS=false \
 ATTRIBUTES_TO_RETAIN=XS ATTRIBUTES_TO_RETAIN=XA \
 MAX_RECORDS_IN_RAM=1000000 \
 TMP_DIR="${mergeBamAlignmentDir}" \
 ATTRIBUTES_TO_RETAIN=X0 \
 IS_BISULFITE_SEQUENCE=false \
 ALIGNED_READS_ONLY=false \
 CLIP_ADAPTERS=true \
 ATTRIBUTES_TO_RETAIN=XS \
 ATTRIBUTES_TO_RETAIN=XA | \
java -Djava.io.tmpdir="${mergeBamAlignmentDir}" -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar SetNmMdAndUqTags \
 INPUT="/dev/stdin" \
 OUTPUT="${mergeBamAlignmentBam}" \
 MAX_RECORDS_IN_RAM=1000000 \
 R="${onekgGenomeFasta}" \
 TMP_DIR="${mergeBamAlignmentDir}" \
 SORT_ORDER=coordinate \
 CREATE_INDEX=true

putFile ${mergeBamAlignmentBam}
putFile ${mergeBamAlignmentBai}

echo "## "$(date)" ##  $0 Done "
