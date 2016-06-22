#!/bin/bash

set -e
set -u

echo "use:[none|exome|rna|nugene|nugrna|iont|withpoly] samplesheet projectname targetsList"

mlCmd='module load Molgenis-Compute/v16.04.1-Java-1.8.0_74'
###module load Molgenis-Compute/v15.11.1-Java-1.8.0_45


#main thing to remember when working with molgenis "/full/paths" ALWAYS!
##here some parameters for customisation

if [ $1 == "none" ];then
	exit 1
elif [ $1 == "exome" ];then
	echo "Using Exome-seq workflow"
	workflowBase="workflow.csv"
	
elif [ $1 == "rna" ];then
        echo "Using RNA-seq workflow"
        workflowBase="workflow_rnaseq.csv"
elif [ $1 == "nugene" ];then
        echo "Using nugene workflow"
        workflowBase="workflow_nugene.csv"
elif [ $1 == "nugrna" ];then
        echo "Using Nugene RNA workflow"
        workflowBase="workflow_nugenerna.csv"
elif [ $1 == "iont" ];then
        echo "Using iontorrent workflow"
        workflowBase="workflow_iont.csv"
elif [ $1 == "withpoly" ];then
        echo "Using Exome-seq with polymorfic  workflow"
        workflowBase="workflow_withPolymorfic.csv"
else
	echo "Erro: No valid Seqtype in input" && exit 1
fi
workflowDir=$(readlink -f $(dirname $0))
samplesheet=$(readlink -f $2)
projectname=$3
if [ -e $4 ];then
	targetsList=$(readlink -f $4)
else
	if [ $4 == "none" ] ; then
		echo "No intervallist"
		targetsList=""
	fi
fi

if [ $HOSTNAME == "pg-interactive" ];then
	echo "setting peregrine molgenis variables"
	runDir=/scratch/$USER/projects/$projectname
	siteParam=$workflowDir/peregrine.siteconfig.csv
	
	cp $siteParam $workflowDir/.parameters.site.tmp.csv
	cp $workflowDir/parameters.csv  $workflowDir/.parameters.tmp.csv
	#partitionFix='perl -i -wpe "s/^#SBATCH\ --partition=ll$/#SBATCH\ --partition=nodes/g"'
elif [ $HOSTNAME == "pg-login" ];then
        echo "setting peregrine molgenis variables"
	runDir=/scratch/$USER/projects/$projectname
        siteParam=$workflowDir/peregrine.siteconfig.csv
	cp $siteParam $workflowDir/.parameters.site.tmp.csv
	cp $workflowDir/parameters.csv  $workflowDir/.parameters.tmp.csv

elif [ $HOSTNAME == "calculon" ];then
        echo "setting calculon molgenis variables"
	group=$(ls -alh $(pwd)| perl -wpe 's/ +/ /g' | cut -f 4 -d " "| tail -n1)
	tmp="tmp04"
	
	runDir=/groups/${group}/${tmp}/projects/$projectname
        siteParam=$workflowDir/umcg.siteconfig.csv
	
	perl -wpe 's/group,gcc/group,'$group'/g' $workflowDir/parameters.csv > $workflowDir/.parameters.tmp.csv
	perl -wpe 's/group,gcc/group,'$group'/g' $siteParam > $workflowDir/.parameters.site.tmp.csv

fi

jobsDir=$runDir/jobs

mkdir -p $jobsDir

#scriptHome=/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/

echo "#progname="$0
echo "#workflowdir="$workflowDir
echo "#workflowBase="$workflowBase
echo "#samplesheet="$samplesheet
#echo "#group="$group
#echo "#tmp="$tmp
#echo "#scriptHome="$scriptHome
echo "#targetsList="$targetsList

#perl -wpe 's/group,gcc/group,'$group'/g' $workflowDir/parameters.csv > $workflowDir/.parameters.tmp.csv
#perl -wpe 's/group,gcc/group,'$group'/g' $siteParam > $workflowDir/.parameters.site.tmp.csv


echo "append targetsList parameter '$targetsList'"
echo "targetsList,"$targetsList>>$workflowDir/.parameters.tmp.csv

echo "Convert parametersheet"
perl $workflowDir/convertParametersGitToMolgenis.pl $workflowDir/.parameters.tmp.csv > $workflowDir/.parameters.molgenis.csv
perl $workflowDir/convertParametersGitToMolgenis.pl $workflowDir/.parameters.site.tmp.csv > $workflowDir/.parameters.site.molgenis.csv

echo "Convert samplesheet"
perl -wpe 's!projectNameHere!'$projectname'!g' $samplesheet > $samplesheet.tmp.csv

cp $samplesheet.tmp.csv $runDir/$(basename $samplesheet)
cp $workflowDir/.parameters.tmp.csv $runDir/parameters.csv

backend="slurm"
molgenisBase=$workflowDir/templates/compute/v15.04.1/$backend/

echo "Generate scripts"
$mlCmd
#module load molgenis_compute/v5_20140522
echo $mlCmd 
#echo $partitionFix $jobsDir'/*.sh'
echo bash ${EBROOTMOLGENISMINCOMPUTE}/molgenis_compute.sh \
 --generate \
 -p $workflowDir/.parameters.molgenis.csv \
 -p $workflowDir/.parameters.site.molgenis.csv \
 -p $samplesheet.tmp.csv \
 -p $workflowDir/scatter_id.csv \
 -w $workflowDir/$workflowBase \
 --backend ${backend} \
 --weave \
 -rundir $jobsDir \
 -header $molgenisBase/header.ftl \
 -submit $molgenisBase/submit.ftl \
 -footer $molgenisBase/footer.ftl

echo -e "perl RemoveDuplicatesCompute.pl $jobsDir/*.sh &>/dev/null"
echo -e "bash $jobsDir/submit.sh"
# -header $MC_HOME/templates/pbs/header.ftl \
# -submit $MC_HOME/templates/pbs/submit.ftl \
# -footer $MC_HOME/templates/pbs/footer.ftl 

#what does runid do?
# -runid 02 \
# -header $molgenisBase/templates/pbs/header.ftl \
# -submit $molgenisBase/templates/pbs/submit.ftl \
# -footer $molgenisBase/templates/pbs/footer.ftl 

#rm $samplesheet.tmp.csv
