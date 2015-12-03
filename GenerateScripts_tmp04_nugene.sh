#!/bin/bash

set -e
set -u

echo "use: samplesheet projectname targetsList"

module load Molgenis-Compute/v15.04.1-Java-1.7.0_80

#main thing to remember when working with molgenis "/full/paths" ALWAYS!
#here some parameters for customisation
workflowdir=$(readlink -f $(dirname $0))
samplesheet=$(readlink -f $1)
projectname=$2
if [ -e $3 ] ; then
	targetsList=$(readlink -f $3)
else
	if [ $3 == "none" ] ; then
		echo "No intervallist"
		targetsList=""
	fi 
fi

#ugly way of detecting inheritance
group=$(ls -alh $(pwd)| perl -wpe 's/ +/ /g' | cut -f 4 -d " "| tail -n1)
tmp="tmp04"

runDir=/groups/${group}/${tmp}/projects/$projectname
jobsDir=$runDir/jobs
mkdir -p $jobsDir

scriptHome=/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/

echo "#progname="$0
echo "#workflowdir="$workflowdir
echo "#samplesheet="$samplesheet
echo "#group="$group
echo "#tmp="$tmp
echo "#scriptHome="$scriptHome
echo "#targetsList="$targetsList




perl -wpe 's/group,gcc/group,'$group'/g' $workflowdir/parameters.csv > $workflowdir/parameters.tmp.csv

echo "append targetsList parameter '$targetsList'"
echo "targetsList,"$targetsList>>$workflowdir/parameters.tmp.csv

echo "Convert parametersheet"
perl $scriptHome/convertParametersGitToMolgenis.pl $workflowdir/parameters.tmp.csv > $workflowdir/parameters.molgenis.csv



#rm $workflowdir/parameters.tmp.csv

echo "Convert samplesheet"
perl -wpe 's!projectNameHere!'$projectname'!g' $samplesheet > $samplesheet.tmp.csv




cp $samplesheet.tmp.csv $runDir/$(basename $samplesheet)
cp $workflowdir/parameters.tmp.csv $runDir/parameters.csv


backend="slurm"
molgenisBase=/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/templates/compute/v15.04.1/$backend/

echo "Generate scripts"
#module load molgenis_compute/v5_20140522
echo bash ${EBROOTMOLGENISMINCOMPUTE}/molgenis_compute.sh \
 --generate \
 -p $workflowdir/parameters.molgenis.csv \
 -p $samplesheet.tmp.csv \
 -p $workflowdir/scatter_id.csv \
 -w $workflowdir/workflow_nugene.csv \
 --backend ${backend} \
 --weave \
 -rundir $jobsDir \
 -header $molgenisBase/header.ftl \
 -submit $molgenisBase/submit.ftl \
 -footer $molgenisBase/footer.ftl 

# -header $MC_HOME/templates/pbs/header.ftl \
# -submit $MC_HOME/templates/pbs/submit.ftl \
# -footer $MC_HOME/templates/pbs/footer.ftl 

#what does runid do?
# -runid 02 \
# -header $molgenisBase/templates/pbs/header.ftl \
# -submit $molgenisBase/templates/pbs/submit.ftl \
# -footer $molgenisBase/templates/pbs/footer.ftl 

#rm $samplesheet.tmp.csv
