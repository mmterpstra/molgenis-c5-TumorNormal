#PBS -N Fastqc_1
#PBS -q gcc
#PBS -l nodes=1:ppn=1
#PBS -l walltime=10:00:00
#PBS -l mem=1gb
#PBS -e Fastqc_1.err
#PBS -o Fastqc_1.out
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
        MC_tmpFolder=$dir/tmp_Fastqc_1_$myMD5array/
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
	echo "$errorCode: $errorMessage --- TASK 'Fastqc_1.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/Fastqc_1.sh.started


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
	echo "$errorCode: $errorMessage --- TASK 'Fastqc_1.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER RUNNING $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/Fastqc_1.sh.started

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
taskId="Fastqc_1"

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
pairedEndfastqcZip2="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_2.fq_fastqc.zip"
fastqcMod="FastQC/0.11.3-Java-1.7.0_80"
sampleName="sampleSE"
fastqcDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/"
checkStage="module list"
WORKDIR="/gcc/"
pairedEndfastqcZip1="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_1.fq_fastqc.zip"
projectDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test/"
stage="module load"
reads2FqGz=""
fastqcZipExt="_fastqc.zip"
reads1FqGz="/target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz"
singleEndfastqcZip="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE.fq_fastqc.zip"

# Validate that each 'value' parameter has only identical values in its list
# We do that to protect you against parameter values that might not be correctly set at runtime.
if [[ ! $(IFS=$'\n' sort -u <<< "${pairedEndfastqcZip2[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'pairedEndfastqcZip2' is an array with different values. Maybe 'pairedEndfastqcZip2' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${fastqcMod[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'fastqcMod' is an array with different values. Maybe 'fastqcMod' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${sampleName[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'sampleName' is an array with different values. Maybe 'sampleName' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${fastqcDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'fastqcDir' is an array with different values. Maybe 'fastqcDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${checkStage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'checkStage' is an array with different values. Maybe 'checkStage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${WORKDIR[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'WORKDIR' is an array with different values. Maybe 'WORKDIR' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${pairedEndfastqcZip1[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'pairedEndfastqcZip1' is an array with different values. Maybe 'pairedEndfastqcZip1' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${projectDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'projectDir' is an array with different values. Maybe 'projectDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${stage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'stage' is an array with different values. Maybe 'stage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${reads2FqGz[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'reads2FqGz' is an array with different values. Maybe 'reads2FqGz' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${fastqcZipExt[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'fastqcZipExt' is an array with different values. Maybe 'fastqcZipExt' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${reads1FqGz[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'reads1FqGz' is an array with different values. Maybe 'reads1FqGz' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${singleEndfastqcZip[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'Fastqc': input parameter 'singleEndfastqcZip' is an array with different values. Maybe 'singleEndfastqcZip' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi

#
## Start of your protocol template
#

#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string fastqcMod
#string WORKDIR
#string projectDir
#string fastqcDir
#string fastqcZipExt
#string reads1FqGz
#string reads2FqGz
#string sampleName
#string singleEndfastqcZip
#string pairedEndfastqcZip1
#string pairedEndfastqcZip2

echo -e "test /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz  1: $(basename /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz .gz)_fastqc.zip \n2: $(basename  .gz)_fastqc.zip "

module load FastQC/0.11.3-Java-1.7.0_80
module list

set -x
set -e

echo "## "$(date)" ##  $0 Started "

if [ ${#reads2FqGz} -eq 0 ]; then
	
	echo "## "$(date)" Started single end fastqc"
	alloutputsexist \
	 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz | perl -wpe 's!.*/|\.gz!!g' )_fastqc.zip \
	 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE.fq_fastqc.zip

	getFile /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz
	
	mkdir -p /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/
	cd /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/
	
	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz --outdir /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/
	echo
	cp -v /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz | perl -wpe 's!.*/|\.gz!!g' )_fastqc.zip /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE.fq_fastqc.zip

	##################################################################
	
	cd $OLDPWD

	putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz | perl -wpe 's!.*/|\.gz!!g' )_fastqc.zip
	putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE.fq_fastqc.zip

else
	echo "## "$(date)" Started paired end fastqc"
	
	alloutputsexist \
	 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz | perl -wpe 's!.*/|\.gz!!g' )_fastqc.zip \
	 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n  | perl -wpe 's!.*/|\.gz!!g' )_fastqc.zip \
	 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_1.fq_fastqc.zip \
	 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_2.fq_fastqc.zip

	getFile /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz
	getFile 
	
	mkdir -p /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/
	cd /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/
	
	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz --outdir /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/
	
	cp -v /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz | perl -wpe 's!.*/|\.fastq\.gz|\.fq\.gz|\.fq|\.fastq!!g')_fastqc.zip /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_1.fq_fastqc.zip
	echo
	echo "## "$(date)" reads2FqGz"
	fastqc --noextract  --outdir /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc/
	echo
	cp -v /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n  | perl -wpe 's!.*/|\.gz!!g' )_fastqc.zip /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_2.fq_fastqc.zip

	##################################################################
	cd $OLDPWD
		
	putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n /target/gpfs2/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/raw/head_40000_120830_SN163_0474_BD0WDYACXX_L5_ACTGAT_1.fq.gz | perl -wpe 's!.*/|\.fastq\.gz|\.fq\.gz|\.fq|\.fastq!!g')_fastqc.zip
	putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//$(echo -n  | perl -wpe 's!.*/|\.gz!!g' )_fastqc.zip
	putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_1.fq_fastqc.zip
	putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//fastqc//2_sampleSE_2.fq_fastqc.zip
	
fi

echo "## "$(date)" ##  $0 Done "

#
## End of your protocol template
#

# Save output in environment file: '$ENVIRONMENT_DIR/Fastqc_1.env' with the output vars of this step

echo "" >> $ENVIRONMENT_DIR/Fastqc_1.env
chmod 755 $ENVIRONMENT_DIR/Fastqc_1.env



#
## General footer
#

# Show that we successfully finished
# If this file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/Fastqc_1.sh.finished

echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task Fastqc_1 finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log

if [ -d ${MC_tmpFolder:-} ];
	then
	echo "removed tmpFolder $MC_tmpFolder"
	rm -r $MC_tmpFolder
fi

#
## General footer
#

# Show that we successfully finished. If the .finished file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/Fastqc_1.sh.finished

# Also do bookkeeping
echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task Fastqc_1.sh finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log