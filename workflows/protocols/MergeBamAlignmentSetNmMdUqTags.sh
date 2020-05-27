#MOLGENIS walltime=23:59:00 mem=12gb nodes=1 ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir
#string onekgGenomeFasta
#string picardMod
#string bwaSam
#string revertSamAddOrReplaceReadGroupsDir
#string revertSamAddOrReplaceReadGroupsBam
#string mergeBamAlignmentDir
#string mergeBamAlignmentBam
#string mergeBamAlignmentBai

alloutputsexist \
 ${mergeBamAlignmentBam} ${mergeBamAlignmentBai} 
echo "## "$(date)" ##  $0 Started "

getFile ${revertSamAddOrReplaceReadGroupsBam}
getFile ${bwaSam}

${stage} ${picardMod}
${checkStage}

set -x
set -e
set -o pipefail

mkdir -p ${mergeBamAlignmentDir}

echo "## "$(date)" Start $0"


java -Djava.io.tmpdir="${mergeBamAlignmentDir}" -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar MergeBamAlignment \
 ALIGNED="${bwaSam}" UNMAPPED="${revertSamAddOrReplaceReadGroupsBam}" O="/dev/stdout" \
 R="${onekgGenomeFasta}" \
 SORT_ORDER=coordinate \
 ADD_MATE_CIGAR=true MAX_INSERTIONS_OR_DELETIONS=-1 \
 PRIMARY_ALIGNMENT_STRATEGY=MostDistant \
 UNMAP_CONTAMINANT_READS=false \
 CLIP_OVERLAPPING_READS=true \
 ATTRIBUTES_TO_RETAIN=XS ATTRIBUTES_TO_RETAIN=XA | 
java -Djava.io.tmpdir="${mergeBamAlignmentDir}" -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar SetNmMdAndUqTags \
 I="/dev/stdin" \
 O="${mergeBamAlignmentBam}" \
 R="${onekgGenomeFasta}" \
 CREATE_INDEX=true \
 MAX_RECORDS_IN_RAM=1000000 \
 TMP_DIR="${revertSamAddOrReplaceReadGroupsDir}" 

putFile ${mergeBamAlignmentBam}
putFile ${mergeBamAlignmentBai}

echo "## "$(date)" ##  $0 Done "
