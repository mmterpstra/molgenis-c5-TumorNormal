#PBS -N BwaMemAlignment_0
#PBS -q gcc
#PBS -l nodes=1:ppn=8
#PBS -l walltime=10:00:00
#PBS -l mem=8gb
#PBS -e BwaMemAlignment_0.err
#PBS -o BwaMemAlignment_0.out
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
        MC_tmpFolder=$dir/tmp_BwaMemAlignment_0_$myMD5array/
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
	echo "$errorCode: $errorMessage --- TASK 'BwaMemAlignment_0.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/BwaMemAlignment_0.sh.started


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
	echo "$errorCode: $errorMessage --- TASK 'BwaMemAlignment_0.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER RUNNING $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/BwaMemAlignment_0.sh.started

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
taskId="BwaMemAlignment_0"

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
path="."

# Connect parameters to environment
stage="module load"
toolDir="/gcc//tools/"
WORKDIR="/gcc/"
resDir="/gcc//resources/"
reads1FqGz="/target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz"
bwaMod="BWA/0.7.12-goolf-1.7.20"
reads2FqGz="/gcc/groups/oncogenetics/tmp01/resources/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_2.fq.gz"
nTreads="8"
checkStage="module list"
onekgGenomeFasta="/gcc//resources//b37/indices/human_g1k_v37.fasta"
bwaAlignmentDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/"
onekgGenomeFastaIdxBase="/gcc//resources//b37/indices/human_g1k_v37.fasta"
bwaSam="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/1_samplePE.sam"

# Validate that each 'value' parameter has only identical values in its list
# We do that to protect you against parameter values that might not be correctly set at runtime.
if [[ ! $(IFS=$'\n' sort -u <<< "${stage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'stage' is an array with different values. Maybe 'stage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${toolDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'toolDir' is an array with different values. Maybe 'toolDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${WORKDIR[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'WORKDIR' is an array with different values. Maybe 'WORKDIR' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${resDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'resDir' is an array with different values. Maybe 'resDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${reads1FqGz[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'reads1FqGz' is an array with different values. Maybe 'reads1FqGz' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${bwaMod[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'bwaMod' is an array with different values. Maybe 'bwaMod' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${reads2FqGz[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'reads2FqGz' is an array with different values. Maybe 'reads2FqGz' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${nTreads[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'nTreads' is an array with different values. Maybe 'nTreads' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${checkStage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'checkStage' is an array with different values. Maybe 'checkStage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${onekgGenomeFasta[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'onekgGenomeFasta' is an array with different values. Maybe 'onekgGenomeFasta' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${bwaAlignmentDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'bwaAlignmentDir' is an array with different values. Maybe 'bwaAlignmentDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${onekgGenomeFastaIdxBase[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'onekgGenomeFastaIdxBase' is an array with different values. Maybe 'onekgGenomeFastaIdxBase' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${bwaSam[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'BwaMemAlignment': input parameter 'bwaSam' is an array with different values. Maybe 'bwaSam' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi

#
## Start of your protocol template
#

#MOLGENIS nodes=1 ppn=8 mem=8gb walltime=10:00:00


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string bwaMod
#string WORKDIR
#string resDir
#string toolDir
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string bwaAlignmentDir 
#string bwaSam
#string nTreads
#string reads1FqGz
#string reads2FqGz

echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	/gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/1_samplePE.sam
 
#getFile functions

getFile /gcc//resources//b37/indices/human_g1k_v37.fasta

#Load modules
module load bwa/BWA/0.7.12-goolf-1.7.20

#check modules
module list


set -x
set -e

mkdir -p /gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/


if [ ${#reads2FqGz} -eq 0 ]; then
	getFile /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz
	bwa mem \
	 -M \
	 -t 8 \
	 /gcc//resources//b37/indices/human_g1k_v37.fasta \
	 /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz \
	 > /gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/1_samplePE.sam
else
	getFile /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz
	getFile /gcc/groups/oncogenetics/tmp01/resources/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_2.fq.gz
        bwa mem \
	 -M \
	 -t 8 \
	 /gcc//resources//b37/indices/human_g1k_v37.fasta \
	 /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz \
	 /gcc/groups/oncogenetics/tmp01/resources/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_2.fq.gz \
	 > /gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/1_samplePE.sam
fi

putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//bwa/1_samplePE.sam 

echo "## "$(date)" ##  $0 Done "

#
## End of your protocol template
#

# Save output in environment file: '$ENVIRONMENT_DIR/BwaMemAlignment_0.env' with the output vars of this step

echo "" >> $ENVIRONMENT_DIR/BwaMemAlignment_0.env
chmod 755 $ENVIRONMENT_DIR/BwaMemAlignment_0.env



#
## General footer
#

# Show that we successfully finished
# If this file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/BwaMemAlignment_0.sh.finished

echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task BwaMemAlignment_0 finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log

if [ -d ${MC_tmpFolder:-} ];
	then
	echo "removed tmpFolder $MC_tmpFolder"
	rm -r $MC_tmpFolder
fi

#
## General footer
#

# Show that we successfully finished. If the .finished file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/BwaMemAlignment_0.sh.finished

# Also do bookkeeping
echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task BwaMemAlignment_0.sh finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log