#!/bin/bash
#SBATCH --job-name=${project}_${taskId}
#SBATCH --output=${taskId}.out
#SBATCH --error=${taskId}.err
#SBATCH --time=${walltime}
#SBATCH --cpus-per-task ${ppn}
#SBATCH --mem ${mem}
#SBATCH --open-mode=append
#SBATCH --export=NONE
#SBATCH --get-user-env=30L

set -e
set -u

ENVIRONMENT_DIR='.'

#
# Variables declared in MOLGENIS Compute headers/footers always start with a MC_ prefix.
#
declare MC_jobScript="${taskId}.sh"
declare MC_jobScriptSTDERR="${taskId}.err"
declare MC_jobScriptSTDOUT="${taskId}.out"

#
# File to indicate failure of a complete workflow in
# a central location for log files for all projects.
#
#

#<#noparse>
runName=$(basename $(cd ../ && pwd ))
MC_failedFile="${runName}.pipeline.failed"

declare MC_singleSeperatorLine=$(head -c 120 /dev/zero | tr '\0' '-')
declare MC_doubleSeperatorLine=$(head -c 120 /dev/zero | tr '\0' '=')
declare MC_tmpFolder='tmpFolder'
declare MC_tmpFile='tmpFile'

#
##
### Header functions.
##
#

function errorExitAndCleanUp() {
	local signal=${1}
	local problematicLine=${2}
	local exitStatus=${3:-$?}
	local executionHost=${SLURMD_NODENAME:-$(hostname)}
	local errorMessage="FATAL: Trapped ${signal} signal in ${MC_jobScript} running on ${executionHost}. Exit status code was ${exitStatus}."
	if [ $signal == 'ERR' ]; then
		local errorMessage="FATAL: Trapped ${signal} signal on line ${problematicLine} in ${MC_jobScript} running on ${executionHost}. Exit status code was ${exitStatus}."
	fi
	local errorMessage=${4:-"${errorMessage}"} # Optionally use custom error message as third argument.
	local format='INFO: Last 50 lines or less of %s:\n'
	echo "${errorMessage}"
	echo "${MC_doubleSeperatorLine}"                > ${MC_failedFile}
	echo "${errorMessage}"                         >> ${MC_failedFile}

	if [ -f "${MC_jobScriptSTDERR}" ]; then
		echo "${MC_singleSeperatorLine}"           >> ${MC_failedFile}
		printf "${format}" "${MC_jobScriptSTDERR}" >> ${MC_failedFile}
		echo "${MC_singleSeperatorLine}"           >> ${MC_failedFile}
		tail -50 "${MC_jobScriptSTDERR}"           >> ${MC_failedFile}
		
	fi
	if [ -f "${MC_jobScriptSTDOUT}" ]; then
		echo "${MC_singleSeperatorLine}"           >> ${MC_failedFile}
		printf "${format}" "${MC_jobScriptSTDOUT}" >> ${MC_failedFile}
		echo "${MC_singleSeperatorLine}"           >> ${MC_failedFile}
		tail -50 "${MC_jobScriptSTDOUT}"           >> ${MC_failedFile}
	fi
	echo "${MC_doubleSeperatorLine}"               >> ${MC_failedFile}
	if [ -d ${MC_tmpFolder} ]; then
		rm -rf ${MC_tmpFolder}
	fi
}

#
# Create tmp dir per script/job.
# To be called with with either a file or folder as first and only argument.
# Defines two globally set variables:
#  1. MC_tmpFolder: a tmp dir for this job/script. When function is called multiple times MC_tmpFolder will always be the same.
#  2. MC_tmpFile:   when the first argument was a folder, MC_tmpFile == MC_tmpFolder
#                   when the first argument was a file, MC_tmpFile will be a path to a tmp file inside MC_tmpFolder.
#
function makeTmpDir {
	local originalPath=$1
	local myMD5=$(md5sum ${MC_jobScript})
	myMD5=${myMD5%% *} # remove everything after the first space character to keep only the MD5 checksum itself.
	local tmpSubFolder="tmp_${MC_jobScript}_${myMD5}"
	local dir
	local base
	if [[ -d "${originalPath}" ]]; then
		dir="${originalPath}"
		base=''
	else
		base=$(basename "${originalPath}")
		dir=$(dirname "${originalPath}")
	fi
	MC_tmpFolder="${dir}/${tmpSubFolder}/"
	MC_tmpFile="$MC_tmpFolder/${base}"
	echo "DEBUG ${MC_jobScript}::makeTmpDir: dir='${dir}';base='${base}';MC_tmpFile='${MC_tmpFile}'"
	mkdir -p ${MC_tmpFolder}
}

trap 'errorExitAndCleanUp HUP  NA $?' HUP
trap 'errorExitAndCleanUp INT  NA $?' INT
trap 'errorExitAndCleanUp QUIT NA $?' QUIT
trap 'errorExitAndCleanUp TERM NA $?' TERM
trap 'errorExitAndCleanUp EXIT NA $?' EXIT
trap 'errorExitAndCleanUp ERR  $LINENO $?' ERR

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
        MC_tmpFolder=$dir/tmp_${taskId}_$myMD5array/
        mkdir -p $MC_tmpFolder
        if [[ -d $1 ]]
        then
            	MC_tmpFile="$MC_tmpFolder"
        else
            	MC_tmpFile="$MC_tmpFolder/$base"
        fi
}

#<#noparse>

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
	touch -- "$@".done
}

alloutputsexist()
{
  all_exist=true
  for name in $@
  do
    if [ ! -e $name ]|| [ ! -e $name.done ];
    then
        all_exist=false
        if [ -e $name ];then
            rm -r -v -- "${name}";
	fi
	if [ -e $name.done ];then
            rm -r -v -- "${name}.done";
        fi

    fi
  done
  if $all_exist;
  then
      echo "skipped"
      echo "skipped" >&2
      touch "${taskId}.env"
      chmod u+rx "${taskId}.env"
      chmod go+rX "${taskId}.env"

      mv "${taskId}.sh.started" "${taskId}.sh.finished"
      sleep 20s
      exit 0;

  else
      return 0;
  fi
}


touch ${MC_jobScript}.started

#</#noparse>

#
# When dealing with timing / synchronization issues of large parallel file systems,
# you can uncomment the sleep statement below to allow for flushing of IO buffers/caches.
#
sleep 4

