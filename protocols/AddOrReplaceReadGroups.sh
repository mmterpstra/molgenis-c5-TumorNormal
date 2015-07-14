#MOLGENIS walltime=23:59:00 mem=6gb nodes=1 ppn=4

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir

#string picardVersion
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

${stage} picard-tools/${picardVersion}
${checkStage}

set -x
set -e

mkdir -p ${addOrReplaceGroupsDir}

echo "## "$(date)" Start $0"

java -Xmx6g -XX:ParallelGCThreads=4 -jar $PICARD_HOME/picard.jar AddOrReplaceReadGroups\
 INPUT=${bwaSam} \
 OUTPUT=${addOrReplaceGroupsBam} \
 SORT_ORDER=coordinate \
 RGID=${internalId} \
 RGLB=${sampleName}_${samplePrep} \
 RGPL=${sequencer} \
 RGPU=${seqType}_${sequencerId}_${flowcellId}_${run}_${lane}_${barcode} \
 RGSM=${sampleName} \
 RGDT=$(date --rfc-3339=date) \
 CREATE_INDEX=true \
 MAX_RECORDS_IN_RAM=4000000 \
 TMP_DIR=${addOrReplaceGroupsDir} \



putFile ${addOrReplaceGroupsBam}
putFile ${addOrReplaceGroupsBai}

if [ ! -z "$PBS_JOBID" ]; then
	echo "## "$(date)" Collecting PBS job statistics"
	qstat -f $PBS_JOBID
fi

echo "## "$(date)" ##  $0 Done "
