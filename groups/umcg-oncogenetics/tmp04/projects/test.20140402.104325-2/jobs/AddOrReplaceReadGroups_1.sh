
#
## Header for 'local' backend
#

#highly recommended to use
#set -e # exit if any subcommand or pipeline returns a non-zero status
#set -u # exit if any uninitialised variable is used

# Set location of *.env and *.log files
ENVIRONMENT_DIR="."

# If you detect an error, then exit your script by calling this function
exitWithError(){
	errorCode=$1
	errorMessage=$2
	echo "$errorCode: $errorMessage --- TASK 'AddOrReplaceReadGroups_1.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER RUNNING $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/AddOrReplaceReadGroups_1.sh.started

getFile()
{
        ARGS=($@)
        NUMBER="${#ARGS[@]}";
        if [ "$NUMBER" -eq "1" ]
        then
                myFile=${ARGS[0]}

                if test ! -e $myFile;
                then
                                echo "WARNING in getFile/putFile: $myFile is missing" 1>&2
                fi

        else
                echo "Example usage: getData \"\$TMPDIR/datadir/myfile.txt\""
        fi
}

putFile()
{
        `getFile $@`
}

inputs()
{
  for name in $@
  do
    if test ! -e $name;
    then
      echo "$name is missing" 1>&2
      exit 1;
    fi
  done
}

outputs()
{
  for name in $@
  do
    if test -e $name;
    then
      echo "skipped"
      echo "skipped" 1>&2
      exit 0;
    else
      return;
    fi
  done
}

alloutputsexist()
{
  all_exist=true
  for name in $@
  do
    if test ! -e $name;
    then
        all_exist=false
    fi
  done
  if $all_exist;
  then
      echo "skipped"
      echo "skipped" 1>&2
      sleep 30
      exit 0;
  else
      return 0;
  fi
}

#
## End of header for 'local' backend
#

#
## Generated header
#

# Assign values to the parameters in this script

# Set taskId, which is the job name of this task
taskId="AddOrReplaceReadGroups_1"

# Make compute.properties available
rundir="/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/groups/umcg-oncogenetics/tmp04/projects/test.20140402.104325-2/jobs"
runid="zBpX"
workflow="/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/workflow_test.csv"
parameters="/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/parameters.molgenis.csv,/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/samplesheet.csv.tmp.csv,/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/scatter_id.csv"
user="umcg-mterpstra"
database="none"
backend="pbs"
port="8080"
interval="2000"
path="./"
# Load parameters from previous steps
source $ENVIRONMENT_DIR/user.env

source $ENVIRONMENT_DIR/BwaMemAlignment_1.env


# Connect parameters to environment
internalId="2"
checkStage="module list"
projectDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test/"
addOrReplaceGroupsBai="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/2_sampleSE.bai"
lane="6"
addOrReplaceGroupsBam="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/2_sampleSE.bam"
run="0474"
sequencer="illumina"
addOrReplaceGroupsDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/"
stage="module load"
seqType="hiseq2500"
picardMod="picard/1.130-Java-1.7.0_80"
flowcellId="BD0WDYACXX"
bwaSam="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/2_sampleSE.sam"
samplePrep="000002"
sequencerId="SN163"
sampleName="sampleSE"
barcode="NNNNNN"
WORKDIR="/gcc/"

# Validate that each 'value' parameter has only identical values in its list
# We do that to protect you against parameter values that might not be correctly set at runtime.
if [[ ! $(IFS=$'\n' sort -u <<< "${internalId[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'internalId' is an array with different values. Maybe 'internalId' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${checkStage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'checkStage' is an array with different values. Maybe 'checkStage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${projectDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'projectDir' is an array with different values. Maybe 'projectDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${addOrReplaceGroupsBai[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'addOrReplaceGroupsBai' is an array with different values. Maybe 'addOrReplaceGroupsBai' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${lane[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'lane' is an array with different values. Maybe 'lane' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${addOrReplaceGroupsBam[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'addOrReplaceGroupsBam' is an array with different values. Maybe 'addOrReplaceGroupsBam' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${run[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'run' is an array with different values. Maybe 'run' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${sequencer[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'sequencer' is an array with different values. Maybe 'sequencer' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${addOrReplaceGroupsDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'addOrReplaceGroupsDir' is an array with different values. Maybe 'addOrReplaceGroupsDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${stage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'stage' is an array with different values. Maybe 'stage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${seqType[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'seqType' is an array with different values. Maybe 'seqType' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${picardMod[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'picardMod' is an array with different values. Maybe 'picardMod' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${flowcellId[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'flowcellId' is an array with different values. Maybe 'flowcellId' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${bwaSam[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'bwaSam' is an array with different values. Maybe 'bwaSam' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${samplePrep[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'samplePrep' is an array with different values. Maybe 'samplePrep' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${sequencerId[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'sequencerId' is an array with different values. Maybe 'sequencerId' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${sampleName[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'sampleName' is an array with different values. Maybe 'sampleName' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${barcode[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'barcode' is an array with different values. Maybe 'barcode' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${WORKDIR[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'AddOrReplaceReadGroups': input parameter 'WORKDIR' is an array with different values. Maybe 'WORKDIR' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi

#
## Start of your protocol template
#

#MOLGENIS walltime=23:59:00 mem=6gb nodes=1 ppn=4

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
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
 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/2_sampleSE.bam \
 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/2_sampleSE.bai

echo "## "$(date)" ##  $0 Started "

getFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/2_sampleSE.sam

module load picard/1.130-Java-1.7.0_80
module list

set -x
set -e

mkdir -p /gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/

echo "## "$(date)" Start $0"

java -Xmx6g -XX:ParallelGCThreads=4 -jar $PICARD_HOME/picard.jar AddOrReplaceReadGroups\
 INPUT=/gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/2_sampleSE.sam \
 OUTPUT=/gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/2_sampleSE.bam \
 SORT_ORDER=coordinate \
 RGID=2 \
 RGLB=sampleSE_000002 \
 RGPL=illumina \
 RGPU=hiseq2500_SN163_BD0WDYACXX_0474_6_NNNNNN \
 RGSM=sampleSE \
 RGDT=$(date --rfc-3339=date) \
 CREATE_INDEX=true \
 MAX_RECORDS_IN_RAM=4000000 \
 TMP_DIR=/gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/ \



putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/2_sampleSE.bam
putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/2_sampleSE.bai

if [ ! -z "$PBS_JOBID" ]; then
	echo "## "$(date)" Collecting PBS job statistics"
	qstat -f $PBS_JOBID
fi

echo "## "$(date)" ##  $0 Done "

#
## End of your protocol template
#

# Save output in environment file: '$ENVIRONMENT_DIR/AddOrReplaceReadGroups_1.env' with the output vars of this step

echo "" >> $ENVIRONMENT_DIR/AddOrReplaceReadGroups_1.env


#
## General footer
#

# Show that we successfully finished. If the .finished file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/AddOrReplaceReadGroups_1.sh.finished

# Also do bookkeeping
echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task AddOrReplaceReadGroups_1.sh finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log