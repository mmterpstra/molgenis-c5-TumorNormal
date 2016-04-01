
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
	echo "$errorCode: $errorMessage --- TASK 'CreatePaddedTargets_0.sh' --- ON $(date +"%Y-%m-%d %T"), AFTER RUNNING $(( ($(date +%s) - $MOLGENIS_START) / 60 )) MINUTES" >> $ENVIRONMENT_DIR/molgenis.error.log
	exit $errorCode
}

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

# Show that the task has started
touch $ENVIRONMENT_DIR/CreatePaddedTargets_0.sh.started

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
taskId="CreatePaddedTargets_0"

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



# Connect parameters to environment
targetsList=""
scatterList[0]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0001_of_*/scattered.intervals"
scatterList[1]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0002_of_*/scattered.intervals"
scatterList[2]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0003_of_*/scattered.intervals"
scatterList[3]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0004_of_*/scattered.intervals"
scatterList[4]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0005_of_*/scattered.intervals"
scatterList[5]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0006_of_*/scattered.intervals"
scatterList[6]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0007_of_*/scattered.intervals"
scatterList[7]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0008_of_*/scattered.intervals"
scatterList[8]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0009_of_*/scattered.intervals"
scatterList[9]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0010_of_*/scattered.intervals"
scatterList[10]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0011_of_*/scattered.intervals"
scatterList[11]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0012_of_*/scattered.intervals"
scatterList[12]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0013_of_*/scattered.intervals"
scatterList[13]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0014_of_*/scattered.intervals"
scatterList[14]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0015_of_*/scattered.intervals"
scatterList[15]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0016_of_*/scattered.intervals"
scatterList[16]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0017_of_*/scattered.intervals"
scatterList[17]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0018_of_*/scattered.intervals"
scatterList[18]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0019_of_*/scattered.intervals"
scatterList[19]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0020_of_*/scattered.intervals"
scatterList[20]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0021_of_*/scattered.intervals"
scatterList[21]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0022_of_*/scattered.intervals"
scatterList[22]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0023_of_*/scattered.intervals"
scatterList[23]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0024_of_*/scattered.intervals"
scatterList[24]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0025_of_*/scattered.intervals"
scatterList[25]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0026_of_*/scattered.intervals"
scatterList[26]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0027_of_*/scattered.intervals"
scatterList[27]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0028_of_*/scattered.intervals"
scatterList[28]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0029_of_*/scattered.intervals"
scatterList[29]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0030_of_*/scattered.intervals"
scatterList[30]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0031_of_*/scattered.intervals"
scatterList[31]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0032_of_*/scattered.intervals"
scatterList[32]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0033_of_*/scattered.intervals"
scatterList[33]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0034_of_*/scattered.intervals"
scatterList[34]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0035_of_*/scattered.intervals"
scatterList[35]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0036_of_*/scattered.intervals"
scatterList[36]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0037_of_*/scattered.intervals"
scatterList[37]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0038_of_*/scattered.intervals"
scatterList[38]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0039_of_*/scattered.intervals"
scatterList[39]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0040_of_*/scattered.intervals"
scatterList[40]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0041_of_*/scattered.intervals"
scatterList[41]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0042_of_*/scattered.intervals"
scatterList[42]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0043_of_*/scattered.intervals"
scatterList[43]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0044_of_*/scattered.intervals"
scatterList[44]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0045_of_*/scattered.intervals"
scatterList[45]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0046_of_*/scattered.intervals"
scatterList[46]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0047_of_*/scattered.intervals"
scatterList[47]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0048_of_*/scattered.intervals"
scatterList[48]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0049_of_*/scattered.intervals"
scatterList[49]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0050_of_*/scattered.intervals"
scatterList[50]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0001_of_*/scattered.intervals"
scatterList[51]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0002_of_*/scattered.intervals"
scatterList[52]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0003_of_*/scattered.intervals"
scatterList[53]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0004_of_*/scattered.intervals"
scatterList[54]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0005_of_*/scattered.intervals"
scatterList[55]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0006_of_*/scattered.intervals"
scatterList[56]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0007_of_*/scattered.intervals"
scatterList[57]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0008_of_*/scattered.intervals"
scatterList[58]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0009_of_*/scattered.intervals"
scatterList[59]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0010_of_*/scattered.intervals"
scatterList[60]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0011_of_*/scattered.intervals"
scatterList[61]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0012_of_*/scattered.intervals"
scatterList[62]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0013_of_*/scattered.intervals"
scatterList[63]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0014_of_*/scattered.intervals"
scatterList[64]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0015_of_*/scattered.intervals"
scatterList[65]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0016_of_*/scattered.intervals"
scatterList[66]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0017_of_*/scattered.intervals"
scatterList[67]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0018_of_*/scattered.intervals"
scatterList[68]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0019_of_*/scattered.intervals"
scatterList[69]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0020_of_*/scattered.intervals"
scatterList[70]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0021_of_*/scattered.intervals"
scatterList[71]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0022_of_*/scattered.intervals"
scatterList[72]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0023_of_*/scattered.intervals"
scatterList[73]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0024_of_*/scattered.intervals"
scatterList[74]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0025_of_*/scattered.intervals"
scatterList[75]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0026_of_*/scattered.intervals"
scatterList[76]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0027_of_*/scattered.intervals"
scatterList[77]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0028_of_*/scattered.intervals"
scatterList[78]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0029_of_*/scattered.intervals"
scatterList[79]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0030_of_*/scattered.intervals"
scatterList[80]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0031_of_*/scattered.intervals"
scatterList[81]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0032_of_*/scattered.intervals"
scatterList[82]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0033_of_*/scattered.intervals"
scatterList[83]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0034_of_*/scattered.intervals"
scatterList[84]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0035_of_*/scattered.intervals"
scatterList[85]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0036_of_*/scattered.intervals"
scatterList[86]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0037_of_*/scattered.intervals"
scatterList[87]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0038_of_*/scattered.intervals"
scatterList[88]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0039_of_*/scattered.intervals"
scatterList[89]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0040_of_*/scattered.intervals"
scatterList[90]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0041_of_*/scattered.intervals"
scatterList[91]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0042_of_*/scattered.intervals"
scatterList[92]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0043_of_*/scattered.intervals"
scatterList[93]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0044_of_*/scattered.intervals"
scatterList[94]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0045_of_*/scattered.intervals"
scatterList[95]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0046_of_*/scattered.intervals"
scatterList[96]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0047_of_*/scattered.intervals"
scatterList[97]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0048_of_*/scattered.intervals"
scatterList[98]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0049_of_*/scattered.intervals"
scatterList[99]="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0050_of_*/scattered.intervals"
checkStage="module list"
stage="module load"
scatterIDs[0]="0001"
scatterIDs[1]="0002"
scatterIDs[2]="0003"
scatterIDs[3]="0004"
scatterIDs[4]="0005"
scatterIDs[5]="0006"
scatterIDs[6]="0007"
scatterIDs[7]="0008"
scatterIDs[8]="0009"
scatterIDs[9]="0010"
scatterIDs[10]="0011"
scatterIDs[11]="0012"
scatterIDs[12]="0013"
scatterIDs[13]="0014"
scatterIDs[14]="0015"
scatterIDs[15]="0016"
scatterIDs[16]="0017"
scatterIDs[17]="0018"
scatterIDs[18]="0019"
scatterIDs[19]="0020"
scatterIDs[20]="0021"
scatterIDs[21]="0022"
scatterIDs[22]="0023"
scatterIDs[23]="0024"
scatterIDs[24]="0025"
scatterIDs[25]="0026"
scatterIDs[26]="0027"
scatterIDs[27]="0028"
scatterIDs[28]="0029"
scatterIDs[29]="0030"
scatterIDs[30]="0031"
scatterIDs[31]="0032"
scatterIDs[32]="0033"
scatterIDs[33]="0034"
scatterIDs[34]="0035"
scatterIDs[35]="0036"
scatterIDs[36]="0037"
scatterIDs[37]="0038"
scatterIDs[38]="0039"
scatterIDs[39]="0040"
scatterIDs[40]="0041"
scatterIDs[41]="0042"
scatterIDs[42]="0043"
scatterIDs[43]="0044"
scatterIDs[44]="0045"
scatterIDs[45]="0046"
scatterIDs[46]="0047"
scatterIDs[47]="0048"
scatterIDs[48]="0049"
scatterIDs[49]="0050"
scatterIDs[50]="0001"
scatterIDs[51]="0002"
scatterIDs[52]="0003"
scatterIDs[53]="0004"
scatterIDs[54]="0005"
scatterIDs[55]="0006"
scatterIDs[56]="0007"
scatterIDs[57]="0008"
scatterIDs[58]="0009"
scatterIDs[59]="0010"
scatterIDs[60]="0011"
scatterIDs[61]="0012"
scatterIDs[62]="0013"
scatterIDs[63]="0014"
scatterIDs[64]="0015"
scatterIDs[65]="0016"
scatterIDs[66]="0017"
scatterIDs[67]="0018"
scatterIDs[68]="0019"
scatterIDs[69]="0020"
scatterIDs[70]="0021"
scatterIDs[71]="0022"
scatterIDs[72]="0023"
scatterIDs[73]="0024"
scatterIDs[74]="0025"
scatterIDs[75]="0026"
scatterIDs[76]="0027"
scatterIDs[77]="0028"
scatterIDs[78]="0029"
scatterIDs[79]="0030"
scatterIDs[80]="0031"
scatterIDs[81]="0032"
scatterIDs[82]="0033"
scatterIDs[83]="0034"
scatterIDs[84]="0035"
scatterIDs[85]="0036"
scatterIDs[86]="0037"
scatterIDs[87]="0038"
scatterIDs[88]="0039"
scatterIDs[89]="0040"
scatterIDs[90]="0041"
scatterIDs[91]="0042"
scatterIDs[92]="0043"
scatterIDs[93]="0044"
scatterIDs[94]="0045"
scatterIDs[95]="0046"
scatterIDs[96]="0047"
scatterIDs[97]="0048"
scatterIDs[98]="0049"
scatterIDs[99]="0050"
slopTargetsList="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//targets.slop100.list"
projectDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test/"
scatterIntervallistDir="/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/"
picardMod="picard/1.130-Java-1.7.0_80"

# Validate that each 'value' parameter has only identical values in its list
# We do that to protect you against parameter values that might not be correctly set at runtime.
if [[ ! $(IFS=$'\n' sort -u <<< "${targetsList[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'CreatePaddedTargets': input parameter 'targetsList' is an array with different values. Maybe 'targetsList' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${checkStage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'CreatePaddedTargets': input parameter 'checkStage' is an array with different values. Maybe 'checkStage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${stage[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'CreatePaddedTargets': input parameter 'stage' is an array with different values. Maybe 'stage' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${slopTargetsList[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'CreatePaddedTargets': input parameter 'slopTargetsList' is an array with different values. Maybe 'slopTargetsList' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${projectDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'CreatePaddedTargets': input parameter 'projectDir' is an array with different values. Maybe 'projectDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${scatterIntervallistDir[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'CreatePaddedTargets': input parameter 'scatterIntervallistDir' is an array with different values. Maybe 'scatterIntervallistDir' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi
if [[ ! $(IFS=$'\n' sort -u <<< "${picardMod[*]}" | wc -l | sed -e 's/^[[:space:]]*//') = 1 ]]; then echo "Error in Step 'CreatePaddedTargets': input parameter 'picardMod' is an array with different values. Maybe 'picardMod' is a runtime parameter with 'more variable' values than what was folded on generation-time?" >&2; exit 1; fi

#
## Start of your protocol template
#

MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4


#string stage
#string checkStage
#string picardMod
#string projectDir

#string targetsList
#string slopTargetsList
#string scatterIntervallistDir
#list scatterIDs,scatterList

#scatList scatIds need to be here because of molgenis duplicating array values
scatIds=($(printf '%s\n' "0001" "0002" "0003" "0004" "0005" "0006" "0007" "0008" "0009" "0010" "0011" "0012" "0013" "0014" "0015" "0016" "0017" "0018" "0019" "0020" "0021" "0022" "0023" "0024" "0025" "0026" "0027" "0028" "0029" "0030" "0031" "0032" "0033" "0034" "0035" "0036" "0037" "0038" "0039" "0040" "0041" "0042" "0043" "0044" "0045" "0046" "0047" "0048" "0049" "0050" "0001" "0002" "0003" "0004" "0005" "0006" "0007" "0008" "0009" "0010" "0011" "0012" "0013" "0014" "0015" "0016" "0017" "0018" "0019" "0020" "0021" "0022" "0023" "0024" "0025" "0026" "0027" "0028" "0029" "0030" "0031" "0032" "0033" "0034" "0035" "0036" "0037" "0038" "0039" "0040" "0041" "0042" "0043" "0044" "0045" "0046" "0047" "0048" "0049" "0050" | sort -u ))
scatList=($(printf '%s\n' "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0001_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0002_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0003_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0004_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0005_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0006_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0007_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0008_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0009_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0010_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0011_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0012_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0013_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0014_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0015_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0016_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0017_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0018_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0019_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0020_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0021_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0022_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0023_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0024_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0025_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0026_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0027_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0028_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0029_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0030_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0031_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0032_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0033_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0034_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0035_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0036_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0037_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0038_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0039_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0040_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0041_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0042_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0043_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0044_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0045_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0046_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0047_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0048_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0049_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0050_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0001_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0002_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0003_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0004_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0005_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0006_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0007_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0008_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0009_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0010_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0011_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0012_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0013_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0014_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0015_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0016_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0017_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0018_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0019_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0020_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0021_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0022_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0023_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0024_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0025_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0026_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0027_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0028_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0029_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0030_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0031_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0032_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0033_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0034_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0035_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0036_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0037_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0038_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0039_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0040_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0041_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0042_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0043_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0044_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0045_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0046_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0047_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0048_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0049_of_*/scattered.intervals" "/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/temp_0050_of_*/scattered.intervals" | sort -u ))
scatCount=$(printf '%s\n' "${scatIds[@]}" | wc -l )

#alloutputsext
alloutputsexist \
 /gcc/groups/umcg-oncogenetics/tmp01/projects/test//targets.slop100.list \
 ${scatList[*]} 
 

echo "## "$(date)" Start $0"

getFile 

#load modules
module load picard/1.130-Java-1.7.0_80
module list

set -x
set -e

#main ceate dir and run programmes

mkdir -p /gcc/groups/umcg-oncogenetics/tmp01/projects/test/

if [ ${#targetsList} -ne 0 ]; then
	
	#Run Picard
	java -jar  -Xmx4g -XX:ParallelGCThreads=4 $PICARD_HOME/picard.jar IntervalListTools \
	 INPUT= \
	 OUTPUT=/gcc/groups/umcg-oncogenetics/tmp01/projects/test//targets.slop100.list \
	 PADDING=150 \
	 UNIQUE=true \
	 COMMENT="Added padding of 100bp and merge overlapping and adjacent intervals to create a list of unique intervals PADDING=150 UNIQUE=true"
	
	putFile /gcc/groups/umcg-oncogenetics/tmp01/projects/test//targets.slop100.list
	
	echo "scatCount="$scatCount" countofids="${#scatterIDs[@]}" Ids="${scatterIDs[*]} 
	
	mkdir -p /gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/
	
	java -jar  -Xmx4g -XX:ParallelGCThreads=4 $PICARD_HOME/picard.jar IntervalListTools \
	 INPUT= \
	 OUTPUT=/gcc/groups/umcg-oncogenetics/tmp01/projects/test//scatter/ \
	 PADDING=150 \
	 UNIQUE=true \
	 SCATTER_COUNT=$scatCount \
	 COMMENT="Added padding of 100bp and merge overlapping and adjacent intervals to create a list of unique intervals PADDING=150 UNIQUE=true"
	
	for l in ${scatList[*]}; do 
		if [ -e $l ]; then 
			putFile $l
		fi
	done

fi

echo "## "$(date)" ##  $0 Done "

#
## End of your protocol template
#

# Save output in environment file: '$ENVIRONMENT_DIR/CreatePaddedTargets_0.env' with the output vars of this step

echo "" >> $ENVIRONMENT_DIR/CreatePaddedTargets_0.env


#
## General footer
#

# Show that we successfully finished. If the .finished file exists, then this step will be skipped when you resubmit your workflow 
touch $ENVIRONMENT_DIR/CreatePaddedTargets_0.sh.finished

# Also do bookkeeping
echo "On $(date +"%Y-%m-%d %T"), after $(( ($(date +%s) - $MOLGENIS_START) / 60 )) minutes, task CreatePaddedTargets_0.sh finished successfully" >> $ENVIRONMENT_DIR/molgenis.bookkeeping.log