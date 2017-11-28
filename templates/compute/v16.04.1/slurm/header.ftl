#!/bin/bash
#SBATCH --job-name=${project}_${taskId}
#SBATCH --output=${taskId}.out
#SBATCH --error=${taskId}.err
#SBATCH --partition=${queue}
#SBATCH --time=${walltime}
#SBATCH --cpus-per-task ${ppn}
#SBATCH --mem ${mem}
#SBATCH --nodes ${nodes}
#SBATCH --open-mode=append
#SBATCH --export=NONE
#SBATCH --get-user-env=20L

. ~/.bashrc

ENVIRONMENT_DIR="."
set -e
set -u
#-%j

errorExit()
{
    if [ "${errorAddr}" = "none" ]; then
        echo "mail is not specified"
        exit 1
    fi

    if [ ! -f errorMessageSent.flag ]; then
        echo "script $0 from directory $(pwd) reports failure" | mail -s "ERROR OCCURS" ${errorAddr}
        touch errorMessageSent.flag
    fi
    exit 1
}

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
        MC_tmpFolder=$dir/tmp_${taskId}_$myMD5array/
        mkdir -p $MC_tmpFolder
        if [[ -d $1 ]]
        then
            	MC_tmpFile="$MC_tmpFolder"
        else
            	MC_tmpFile="$MC_tmpFolder/$base"
        fi
}

<#noparse>

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
      touch ${taskId}.env
      chmod u+rx ${taskId}.env
      chmod go+rX ${taskId}.env
      touch ${taskId}.sh.finished
      sleep 20s
      exit 0;

  else
      return 0;
  fi
}

echo "prog:"$0;

trap "errorExit" ERR

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

</#noparse>

touch ${taskId}.sh.started

