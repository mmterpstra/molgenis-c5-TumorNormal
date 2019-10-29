#MOLGENIS walltime=23:59:00 mem=6gb nodes=1 ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
#string samtoolsMod
#string addOrReplaceGroupsDir
#string addOrReplaceGroupsBam
#string addOrReplaceGroupsBai
#string sizeSelectionDir
#string sizeSelectionBam
#string sizeSelectionBai

alloutputsexist \
 ${sizeSelectionBam} \
 ${sizeSelectionBai}

echo "## "$(date)" ##  $0 Started "

getFile ${addOrReplaceGroupsBam} ${addOrReplaceGroupsBai}

${stage} ${picardMod}
${checkStage}

set -x
set -e
set -o pipefail

mkdir -p ${sizeSelectionDir}

echo "## "$(date)" Start $0"



#java -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups\
# INPUT="${bwaSam}" \
# OUTPUT="/dev/stdout" \
# SORT_ORDER=unsorted \
# RGID="${internalId}" \
# RGLB="${sampleName}_${samplePrep}" \
# RGPL="${sequencer}" \
# RGPU="${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode}" \
# RGSM="${sampleName}" \
# RGDT="$(date --rfc-3339=date)" \
# MAX_RECORDS_IN_RAM=1000000 \
# TMP_DIR="${addOrReplaceGroupsDir}" | 
#java -Xmx5g -XX:ParallelGCThreads=2 -Djava.io.tmpdir="${addOrReplaceGroupsDir}" -jar $EBROOTPICARD/picard.jar FixMateInformation \
# INPUT="/dev/stdin" \
# ADD_MATE_CIGAR=true \
# IGNORE_MISSING_MATES=true \
# ASSUME_SORTED=false \
# SORT_ORDER=coordinate \
# CREATE_INDEX=true \
# TMP_DIR="${addOrReplaceGroupsDir}" \
# OUTPUT="${addOrReplaceGroupsBam}"

${stage} ${samtoolsMod}

samtools view -h ${addOrReplaceGroupsBam} | perl -wlane 'print if(m/^@/ ||(not(m/^@/)&& abs($F[8]) <= 150 ))' | samtools view -S -b -h  -  >  ${sizeSelectionBam}
samtools index ${sizeSelectionBam}

${stage} ${picardMod}

java -Xmx5g -XX:ParallelGCThreads=2 -Djava.io.tmpdir="${addOrReplaceGroupsDir}" -jar $EBROOTPICARD/picard.jar CollectInsertSizeMetrics \
      I=${sizeSelectionBam} \
      O=${sizeSelectionBam}.insert_size_metrics.txt \
      H=${sizeSelectionBam}.insert_size_histogram.pdf \
      M=0.5


putFile ${sizeSelectionBam}
putFile ${sizeSelectionBai}


echo "## "$(date)" ##  $0 Done "
