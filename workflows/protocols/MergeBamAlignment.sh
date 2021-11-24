#MOLGENIS walltime=23:59:00 mem=12gb nodes=1 ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
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
#string bwaSam
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


java -Djava.io.tmpdir="${mergeBamAlignmentDir}" -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar MergeBamAlignment \
 ALIGNED="${bwaSam}" UNMAPPED="${revertSamAddOrReplaceReadGroupsBam}" O="/dev/stdout" \
 R=chr19_chr19_KI270866v1_alt.fasta \
 SORT_ORDER=coordinate \
 ADD_MATE_CIGAR=true MAX_INSERTIONS_OR_DELETIONS=-1 \
 PRIMARY_ALIGNMENT_STRATEGY=MostDistant \
 UNMAP_CONTAMINANT_READS=false \
 ATTRIBUTES_TO_RETAIN=XS ATTRIBUTES_TO_RETAIN=XA \
 MAX_RECORDS_IN_RAM=1000000 \
 TMP_DIR="${mergeBamAlignmentDir}" | \
java -Djava.io.tmpdir="${mergeBamAlignmentDir}" -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar SetNmMdAndUqTags \
 INPUT="/dev/stdin" \
 OUTPUT="${mergeBamAlignmentBam}" \
 MAX_RECORDS_IN_RAM=1000000 \
 R=chr19_chr19_KI270866v1_alt.fasta \
 TMP_DIR="${mergeBamAlignmentDir}" \
 SORT_ORDER=coordinate \
 CREATE_INDEX=true

putFile ${mergeBamAlignmentBam}
putFile ${mergeBamAlignmentBai}

echo "## "$(date)" ##  $0 Done "
