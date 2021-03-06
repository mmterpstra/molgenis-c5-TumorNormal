#PBS -N ${taskId}
#PBS -q ${queue}
#PBS -l nodes=${nodes}:ppn=${ppn}
#PBS -l walltime=${walltime}
#PBS -l mem=${mem}
#PBS -e ${taskId}.err
#PBS -o ${taskId}.out
#PBS -W umask=0007

#
## Header for PBS backend
#

echo Running on node: `hostname`

sleep 90s

#highly recommended to use
#set -e # exit if any subcommand or pipeline returns a non-zero status
#set -u # exit if any uninitialised variable is used

# Set location of *.env files
ENVIRONMENT_DIR="$PBS_O_WORKDIR"

# If you detect an error, then exit your script by calling this function
exitWithError(){
	errorCode=$1
	errorMessage=$2
	echo "$errorCode: $errorMessage --- TASK '${taskId}.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/${taskId}.sh.started

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

include $WORKDIR/gcc.bashrc

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
      echo "skipped" >&2
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
    if [ ! -e $name ]|| [ ! -e $name.done ];
    then
        all_exist=false
        if [ -e $name ];then
            rm -v -- "${name}";
	fi
	if [ -e $name.done ];then
            rm -v -- "${name}.done";
        fi

    fi
  done
  if $all_exist;
  then
      echo "skipped"
      echo "skipped" >&2
      touch $ENVIRONMENT_DIR/${PBS_JOBNAME}.env
      touch $ENVIRONMENT_DIR/${PBS_JOBNAME}.sh.finished
      sleep 20s
      exit 0;

  else
      return 0;
  fi
}

echo "prog:"$0;
echo;
echo "envdir:$ENVIRONMENT_DIR"
if [ ! -e $ENVIRONMENT_DIR/$(basename $0 .sh).env ]; then
	echo "" >> $ENVIRONMENT_DIR/${PBS_JOBNAME}.env

fi

</#noparse>

#
## End of header for PBS backend
#
