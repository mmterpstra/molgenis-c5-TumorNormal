#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#string project
###string rundir

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string picardMod
#string targetsList
#string projectDir
#string targetsList

set -x
set -e

echo "## "$(date)" ##  $0 Started "

cd /groups/umcg-oncogenetics/prm02/data/git/molgenis-c5-TumorNormal
if [ ${#targetsList} -eq 0 ]; then
        bash GenerateScripts2.sh iont $(ls ${rundir}/../*.filtered.csv |head -n 1 ) $(basename $(dirname ${rundir})) none && bash .RunWorkFlowGeneration.sh
else
	bash GenerateScripts2.sh iont $(ls ${rundir}/../*.filtered.csv | head -n 1 ) $(basename $(dirname ${rundir})) ${targetsList} && bash .RunWorkFlowGeneration.sh	
fi
#run submit script again


echo "## "$(date)" ##  $0 Done "
