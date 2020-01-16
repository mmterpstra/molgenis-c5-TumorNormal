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
#string addOrReplaceReadGroupsDir
#string addOrReplaceReadGroupsBam
#string addOrReplaceReadGroupsBai


alloutputsexist \
 ${addOrReplaceReadGroupsBam} \
 ${addOrReplaceReadGroupsBai}

echo "## "$(date)" ##  $0 Started "

getFile ${bwaSam}

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${addOrReplaceReadGroupsDir}

echo "## "$(date)" Start $0"

java -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups\
 INPUT="${bwaSam}" \
 OUTPUT="/dev/stdout" \
 SORT_ORDER=unsorted \
 RGID="${internalId}" \
 RGLB="${sampleName}_${samplePrep}" \
 RGPL="${sequencer}" \
 RGPU="${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode}" \
 RGSM="${sampleName}" \
 RGDT="$(date --rfc-3339=date)" \
 MAX_RECORDS_IN_RAM=1000000 \
 TMP_DIR="${addOrReplaceReadGroupsDir}" | 
java -Xmx5g -XX:ParallelGCThreads=2 -Djava.io.tmpdir="${addOrReplaceReadGroupsDir}" -jar $EBROOTPICARD/picard.jar FixMateInformation \
 INPUT="/dev/stdin" \
 ADD_MATE_CIGAR=true \
 IGNORE_MISSING_MATES=true \
 ASSUME_SORTED=false \
 SORT_ORDER=coordinate \
 CREATE_INDEX=true \
 TMP_DIR="${addOrReplaceReadGroupsDir}" \
 OUTPUT="${addOrReplaceReadGroupsBam}"


putFile ${addOrReplaceReadGroupsBam}
putFile ${addOrReplaceReadGroupsBai}


echo "## "$(date)" ##  $0 Done "
