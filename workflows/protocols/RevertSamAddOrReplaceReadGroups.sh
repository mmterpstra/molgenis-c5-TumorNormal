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
#string revertSamAddOrReplaceReadGroupsDir
#string revertSamAddOrReplaceReadGroupsBam


alloutputsexist \
 ${revertSamAddOrReplaceReadGroupsBam} 
echo "## "$(date)" ##  $0 Started "

getFile ${bwaSam}

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${revertSamAddOrReplaceReadGroupsDir}

echo "## "$(date)" Start $0"

java -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar RevertSam \
 I="${bwaSam}" \
 O="/dev/stdout" \
 ATTRIBUTE_TO_CLEAR=XS \
 ATTRIBUTE_TO_CLEAR=XA \
 TMP_DIR=${revertSamAddOrReplaceReadGroupsDir} | \
java -Xmx5g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
 INPUT="/dev/stdin" \
 OUTPUT="${revertSamAddOrReplaceReadGroupsBam}" \
 RGID="${internalId}" \
 RGLB="${sampleName}_${samplePrep}" \
 RGPL="${sequencer}" \
 RGPU="${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode}" \
 RGSM="${sampleName}" \
 RGDT="$(date --rfc-3339=date)" \
 MAX_RECORDS_IN_RAM=1000000 \
 TMP_DIR="${revertSamAddOrReplaceReadGroupsDir}" 


putFile ${revertSamAddOrReplaceReadGroupsBam}


echo "## "$(date)" ##  $0 Done "
