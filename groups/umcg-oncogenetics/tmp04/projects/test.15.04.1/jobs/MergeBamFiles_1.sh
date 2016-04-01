#PBS -N MergeBamFiles_1
#PBS -q gcc
#PBS -l nodes=1:ppn=4
#PBS -l walltime=23:59:00
#PBS -l mem=6gb
#PBS -e MergeBamFiles_1.err
#PBS -o MergeBamFiles_1.out
#PBS -W umask=0007

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

#
## Header for PBS backend
#

declare MC_tmpFolder="tmpFolder"
declare MC_tmpFile="tmpFile"

function makeTmpDir {
 	base=$(basename $1)
        dir=$(dirname $1)
        echo "dir $dir"
        echo "base $base"
        if [[ -d $1 ]]
        then
                dir=$dir/$base
        fi
        myMD5=$(md5sum $0)
        IFS=' ' read -a myMD5array <<< "$myMD5"
        MC_tmpFolder=$dir/tmp_MergeBamFiles_1_$myMD5array/
        mkdir -p $MC_tmpFolder
        if [[ -d $1 ]]
        then
                MC_tmpFile="$MC_tmpFolder"
        else
                MC_tmpFile="$MC_tmpFolder/$base"
        fi
}
echo Running on node: `hostname`

#highly recommended to use
set -e # exit if any subcommand or pipeline returns a non-zero status
set -u # exit if any uninitialised variable is used

# Set location of *.env files
ENVIRONMENT_DIR="$PBS_O_WORKDIR"

# If you detect an error, then exit your script by calling this function
exitWithError(){
	errorCode=$1
	errorMessage=$2
	echo "$errorCode: $errorMessage --- TASK 'MergeBamFiles_1.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/MergeBamFiles_1.sh.started


# Define the root to all your tools and data
WORKDIR=${WORKDIR}

# Source getFile, putFile, inputs, alloutputsexist
include () {
	if [[ -f "$1" ]]; then
		source "$1"
		echo "sourced $1"
	else
		echo "File not found: $1"
	fi		
}
include $GCC_HOME/gcc.bashrc
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
      return 0;
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
## End of header for PBS backend
#


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
	echo "$errorCode: $errorMessage --- TASK 'MergeBamFiles_1.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER RUNNING $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/MergeBamFiles_1.sh.started

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
taskId="MergeBamFiles_1"

# Make compute.properties available
rundir="/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/groups/umcg-oncogenetics/tmp04/projects/test.15.04.1/jobs"
runid="5NYy"
workflow="/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/workflow_test.csv"
parameters="/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/parameters.molgenis.csv,/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/samplesheet.csv.tmp.csv,/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/scatter_id.csv"
user="umcg-mterpstra"
database="none"
backend="pbs"
port="80"
interval="2000"
path="."source $ENVIRONMENT_DIR/AddOrReplaceReadGroups_1.env


# Connect parameters to environment
projectDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test/"
checkStage="module list"
picardMod="picard/1.130-Java-1.7.0_80"
MergeBamFilesBam="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/sampleSE.bam"
WORKDIR="/gcc/"
stage="module load"
MergeBamFilesDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/"
addOrReplaceGroupsDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//addOrReplaceReadGroups/"
MergeBamFilesBai="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/sampleSE.bai"

# Validate that each 'value' parameter has only identical values in its list
# We do that to protect you against parameter values that might not be correctly set at runtime.
if [[ ! $(IFS=$'\n' sort -u <<< "${projectDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'projectDir' is an array with different values. Maybe 'projectDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${checkStage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'checkStage' is an array with different values. Maybe 'checkStage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${picardMod[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'picardMod' is an array with different values. Maybe 'picardMod' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${MergeBamFilesBam[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'MergeBamFilesBam' is an array with different values. Maybe 'MergeBamFilesBam' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${WORKDIR[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'WORKDIR' is an array with different values. Maybe 'WORKDIR' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${stage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'stage' is an array with different values. Maybe 'stage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${MergeBamFilesDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'MergeBamFilesDir' is an array with different values. Maybe 'MergeBamFilesDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${addOrReplaceGroupsDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'addOrReplaceGroupsDir' is an array with different values. Maybe 'addOrReplaceGroupsDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${MergeBamFilesBai[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'MergeBamFiles': input parameter 'MergeBamFilesBai' is an array with different values. Maybe 'MergeBamFilesBai' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi

#
## Start of your protocol template
#

#MOLGENIS walltime=23:59:00 mem=6gb ppn=4

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir

#string picardMod


#string addOrReplaceGroupsDir
#list addOrReplaceGroupsBam
#list addOrReplaceGroupsBai

#string MergeBamFilesDir
#string MergeBamFilesBam
#string MergeBamFilesBai


alloutputsexist \
"/gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/sampleSE.bam" \
"/gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/sampleSE.bai"

echo "## "$(date)" ##  $0 Started "

for file in   ; do
	echo "getFile file='$file'"
	getFile $file
done

#Load Picard module
module load picard/1.130-Java-1.7.0_80
module list

set -o posix

set -x
set -e

#${addOrReplaceGroupsBam} sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n'  | sort -u ))
inputs=$(printf 'INPUT=%s ' $(printf '%s\n' ${bams[@]}))

mkdir -p /gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/

java -Xmx6g -XX:ParallelGCThreads=4 -jar $PICARD_HOME/picard.jar MergeSamFiles \
 $inputs \
 SORT_ORDER=coordinate \
 CREATE_INDEX=true \
 USE_THREADING=true \
 TMP_DIR=/gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/ \
 MAX_RECORDS_IN_RAM=6000000 \
 OUTPUT=/gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/sampleSE.bam \

# VALIDATION_STRINGENCY=LENIENT \

putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/sampleSE.bam
putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//MergeBams/sampleSE.bai

echo "## "$(date)" ##  $0 Done "

#
## End of your protocol template
#

# Save output in environment file: '$ENVIRONMENT_DIR/MergeBamFiles_1.env' with the output vars of this step

echo "" >> $ENVIRONMENT_DIR/MergeBamFiles_1.env
chmod 755 $ENVIRONMENT_DIR/MergeBamFiles_1.env



#
## General footer
#

# Show that we successfully finished
# If this file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/MergeBamFiles_1.sh.finished

echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task MergeBamFiles_1 finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log

if [ -d ${MC_tmpFolder:-} ];
	then
	echo "removed tmpFolder $MC_tmpFolder"
	rm -r $MC_tmpFolder
fi

#
## General footer
#

# Show that we successfully finished. If the .finished file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/MergeBamFiles_1.sh.finished

# Also do bookkeeping
echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task MergeBamFiles_1.sh finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log