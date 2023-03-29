#MOLGENIS nodes=1 ppn=8 mem=17gb walltime=10:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string bwaMod
#string picardMod
#string fgbioMod
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string bwaAlignmentDir 
#string bwaBam
#string bwaBai

#string sampleName
#string sequencer
#string seqType
#string sequencerId
#string flowcellId
#string run
#string lane
#string barcode
#string samplePrep
#string internalId

#string nTreads
#string reads1FqGz
#string reads2FqGz
#string reads3FqGz

#string reads1FqGzOriginal
#string reads2FqGzOriginal
#string reads3FqGzOriginal


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${bwaBam}
 
#getFile functions

getFile ${onekgGenomeFasta}

#Load modules
${stage} ${bwaMod} ${picardMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${bwaAlignmentDir}

#fastq to unmapped bam

BAMTOPROCESS="${bwaBam}.unmapped.bam"

if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	java -Djava.io.tmpdir="${bwaAlignmentDir}" -Xmx1g  -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar FastqToSam \
	 F1="${reads1FqGz}" \
	 OUTPUT="${bwaBam}.unmapped.bam" \
	 SORT_ORDER=queryname \
	 LB="${sampleName}_${samplePrep}" \
	 PL="${sequencer}" \
	 PU="${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode}" \
	 SM="${sampleName}" \
	 DT="$(date --rfc-3339=date)" \
	 MAX_RECORDS_IN_RAM=1000000
else
	java  -Djava.io.tmpdir="${bwaAlignmentDir}" -Xmx1g -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar FastqToSam \
	 F1="${reads1FqGz}" \
	 F2="${reads2FqGz}" \
	 O="${bwaBam}.unmapped.bam" \
	 SORT_ORDER=queryname \
	 LB="${sampleName}_${samplePrep}" \
	 PL="${sequencer}" \
	 PU="${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode}" \
	 SM="${sampleName}" \
	 DT="$(date --rfc-3339=date)" \
	 MAX_RECORDS_IN_RAM=1000000
fi

#add umis if present
if [ ${#reads3FqGzOriginal} -eq 0 ]; then
	echo "No umis here"

else
	ml ${fgbioMod}
	#this piece of code reads the umis in memory so more mem as the reads3 file gets bigger
	#java -Xmx4g  -Djava.io.tmpdir="${bwaAlignmentDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTFGBIO/fgbio.jar FastqToBam \
	# --input "${reads1FqGz}" "${reads2FqGz}" "${reads3FqGz}" --read-structures +T +T +M \
	# --output "${bwaBam}.umi.bam" \
	# --sort true \
	# --sample "${sampleName}" \
	# --library "${sampleName}_${samplePrep}" \
	# --platform "${sequencer}" \
	# --platform-unit "${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode}" \
	# --run-date "$(date --rfc-3339=date)"
	# omitted platform-model sequencing-center predicted-insert-size description comment 

	java -Xmx16g  -Djava.io.tmpdir="${bwaAlignmentDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTFGBIO/fgbio.jar AnnotateBamWithUmis \
	 --input "${bwaBam}.unmapped.bam" \
	 --fastq ${reads3FqGzOriginal} \
	 --output "${bwaBam}.umi.bam" 

	BAMTOPROCESS="${bwaBam}.umi.bam"
fi

#MERGEBAMALIGNMENT
java  -Djava.io.tmpdir="${bwaAlignmentDir}" -Xmx4g  -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar SamToFastq \
 INPUT="$BAMTOPROCESS" \
 FASTQ=/dev/stdout \
 INTERLEAVE=true | \
bwa mem \
 -p \
 -M \
 -t ${nTreads} \
 ${onekgGenomeFastaIdxBase} \
 /dev/stdin | \
java -Djava.io.tmpdir="${bwaAlignmentDir}" -Xmx4g -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar MergeBamAlignment \
 R="${onekgGenomeFasta}" \
 UNMAPPED="$BAMTOPROCESS" \
 ALIGNED="/dev/stdin" \
 OUTPUT="/dev/stdout" \
 SO=coordinate \
 ADD_MATE_CIGAR=true \
 MAX_INSERTIONS_OR_DELETIONS=-1 \
 PRIMARY_ALIGNMENT_STRATEGY=MostDistant \
 UNMAP_CONTAMINANT_READS=false \
 CLIP_OVERLAPPING_READS=true \
 ATTRIBUTES_TO_RETAIN=XS \
 ATTRIBUTES_TO_RETAIN=XA | \
java -Djava.io.tmpdir="${bwaAlignmentDir}" -Xmx4g -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar SetNmMdAndUqTags \
 I="/dev/stdin" \
 O="${bwaBam}" \
 R="${onekgGenomeFasta}" \
 CREATE_INDEX=true \
 MAX_RECORDS_IN_RAM=1000000 \
 TMP_DIR="${bwaAlignmentDir}" 


putFile ${bwaBam} 
putFile ${bwaBai} 
echo "## "$(date)" ##  $0 Done "
