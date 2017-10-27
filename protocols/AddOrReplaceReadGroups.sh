#MOLGENIS walltime=23:59:00 mem=10gb nodes=1 ppn=4

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
#string addOrReplaceGroupsDir
#string addOrReplaceGroupsBam
#string addOrReplaceGroupsBai


alloutputsexist \
 ${addOrReplaceGroupsBam} \
 ${addOrReplaceGroupsBai}

echo "## "$(date)" ##  $0 Started "

getFile ${bwaSam}

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${addOrReplaceGroupsDir}

echo "## "$(date)" Start $0"

java -Xmx8g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups\
 INPUT=${bwaSam} \
 OUTPUT=/dev/stdout \
 SORT_ORDER=coordinate \
 RGID=${internalId} \
 RGLB=${sampleName}_${samplePrep} \
 RGPL=${sequencer} \
 RGPU=${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode} \
 RGSM=${sampleName} \
 RGDT=$(date --rfc-3339=date) \
 MAX_RECORDS_IN_RAM=4000000 \
 TMP_DIR=${addOrReplaceGroupsDir} | 
java -Xmx8g -XX:ParallelGCThreads=2 -Djava.io.tmpdir=${addOrReplaceGroupsDir} -jar $EBROOTPICARD/picard.jar FixMateInformation \
 INPUT=/dev/stdin \
 ADD_MATE_CIGAR=true \
 IGNORE_MISSING_MATES=true \
 ASSUME_SORTED=false \
 CREATE_INDEX=true \
 TMP_DIR=${addOrReplaceGroupsDir} \
 OUTPUT=${addOrReplaceGroupsBam}


putFile ${addOrReplaceGroupsBam}
putFile ${addOrReplaceGroupsBai}


echo "## "$(date)" ##  $0 Done "
