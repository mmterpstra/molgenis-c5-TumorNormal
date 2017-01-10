#!/bin/bash

set -e
set -u

SCRIPTCALL="$0 $@"
>&2 echo "## "$(date)" ## $0 ## Called with call '${SCRIPTCALL}'"
>&2 echo "## "$(date)" ## $0 ## Use:[none|exome|rna|nugene|nugrna|iont|withpoly] samplesheet projectname targetsList"

mlCmd='module load Molgenis-Compute/v16.04.1-Java-1.8.0_74'
###module load Molgenis-Compute/v15.11.1-Java-1.8.0_45


#main thing to remember when working with molgenis "/full/paths" ALWAYS!
#here some parameters for customisation

if [ $1 == "none" ];then
	exit 1
elif [ $1 == "exome" ];then
	>&2 echo  "## "$(date)" ## $0 ## Using Exome-seq workflow"
	workflowBase="workflow.csv"
elif [ $1 == "rna" ];then
        >&2 echo  "## "$(date)" ## $0 ## Using RNA-seq workflow"
        workflowBase="workflow_rnaseq.csv"
elif [ $1 == "nugene" ];then
        >&2 echo  "## "$(date)" ## $0 ## Using nugene workflow"
        workflowBase="workflow_nugene.csv"
elif [ $1 == "nuginc" ];then
        >&2 echo  "## "$(date)" ## $0 ## Using nugene advised workflow"
        workflowBase="workflow_nugeneinc.csv"
elif [ $1 == "nugincbybed" ];then
        >&2 echo  "## "$(date)" ## $0 ## Using nugene advised workflow"
        workflowBase="workflow_nugeneinctrimbybed.csv"
elif [ $1 == "nugrna" ];then
        >&2 echo  "## "$(date)" ## $0 ## Using Nugene RNA workflow"
        workflowBase="workflow_nugenerna.csv"
elif [ $1 == "iont" ];then
        >&2 echo  "## "$(date)" ## $0 ## Using iontorrent workflow"
        workflowBase="workflow_iont.csv"
elif [ $1 == "withpoly" ];then
        >&2 echo  "## "$(date)" ## $0 ## Using Exome-seq with polymorfic  workflow"
        workflowBase="workflow_withPolymorfic.csv"
else
	>&2 echo  "## "$(date)" ## $0 ## Error: No valid Seqtype in input" && exit 1
fi
workflowDir=$(dirname $(which GenerateScripts2.sh 2> /dev/null) 2>/dev/null || readlink -f $(dirname $0))
samplesheet=$(readlink -f $2)
projectname=$3
if [ -e $4 ];then
	targetsList=$(readlink -f $4)
else
	if [ $4 == "none" ] ; then
		>&2 echo  "## "$(date)" ## $0 ## No intervallist"
		targetsList=""
	fi
fi

>&2 echo "## "$(date)" ## $0 ## Running on host '"$HOSTNAME"'."

if [ $HOSTNAME == "pg-interactive" ];then
	>&2 echo "## "$(date)" ## $0 ## Setting peregrine molgenis variables"
	runDir=/scratch/$USER/projects/$projectname
	siteParam=$workflowDir/peregrine.siteconfig.csv

	cp $siteParam $workflowDir/.parameters.site.tmp.csv
	cp $workflowDir/parameters.csv  $workflowDir/.parameters.tmp.csv
	#partitionFix='perl -i -wpe "s/^#SBATCH\ --partition=ll$/#SBATCH\ --partition=nodes/g"'
elif [ $HOSTNAME == "peregrine.hpc.rug.nl" ];then
        >&2 echo "## "$(date)" ## $0 ## Setting peregrine molgenis variables"
        runDir=/scratch/$USER/projects/$projectname
        siteParam=$workflowDir/peregrine.siteconfig.csv

        cp $siteParam $workflowDir/.parameters.site.tmp.csv
        cp $workflowDir/parameters.csv  $workflowDir/.parameters.tmp.csv
        #partitionFix='perl -i -wpe "s/^#SBATCH\ --partition=ll$/#SBATCH\ --partition=nodes/g"'
elif [ $HOSTNAME == "pg-login" ];then
        >&2 echo "## "$(date)" ## $0 ## Setting peregrine molgenis variables"
	runDir=/scratch/$USER/projects/$projectname
        siteParam=$workflowDir/peregrine.siteconfig.csv
	cp $siteParam $workflowDir/.parameters.site.tmp.csv
	cp $workflowDir/parameters.csv  $workflowDir/.parameters.tmp.csv

elif [ $HOSTNAME == "calculon" ];then
        >&2 echo "## "$(date)" ## $0 ## Setting calculon molgenis variables"
	group=$(ls -alh $(pwd)| perl -wpe 's/ +/ /g' | cut -f 4 -d " "| tail -n1)
	tmp="tmp04"

	runDir=/groups/${group}/${tmp}/projects/$projectname
        siteParam=$workflowDir/umcg.siteconfig.csv

	mlCmd='module load Molgenis-Compute/v16.04.1-Java-1.8.0_45'

	perl -wpe 's/group,gcc/group,'$group'/g' $workflowDir/parameters.csv > $workflowDir/.parameters.tmp.csv
	perl -wpe 's/group,gcc/group,'$group'/g' $siteParam > $workflowDir/.parameters.site.tmp.csv
elif [[ "$HOSTNAME" =~ travis-worker-* ]] ; then
	>&2 echo  "## "$(date)" ## $0 ## Setting testing molgenis variables."

	mlCmd="module load Molgenis-Compute"
	runDir=/home/$USER/projects/$projectname
        siteParam=$workflowDir/peregrine.siteconfig.csv
	cp $siteParam $workflowDir/.parameters.site.tmp.csv
        cp $workflowDir/parameters.csv  $workflowDir/.parameters.tmp.csv

elif [[ "$HOSTNAME" =~ testing-* ]] ; then

        >&2 echo "## "$(date)" ## $0 ## Setting testing molgenis variables (2)"

        mlCmd="module load Molgenis-Compute"
        runDir=/home/$USER/projects/$projectname
        siteParam=$workflowDir/peregrine.siteconfig.csv
        cp $siteParam $workflowDir/.parameters.site.tmp.csv
       	cp $workflowDir/parameters.csv  $workflowDir/.parameters.tmp.csv


fi

#backup samplesheets somewhere
if [ -z "${SAMPLESHEETFOLDER+x}" ]; then
	SAMPLESHEETFOLDER="$(dirname $0)/samplesheets/"
fi
if [ -d $SAMPLESHEETFOLDER ]; then
	>&2 echo "## "$(date)" ## $0 ## Copying samplesheet to samplesheets folder '$SAMPLESHEETFOLDER'"
	cp -v "${samplesheet}" "$SAMPLESHEETFOLDER/${HOSTNAME}_"$(basename ${samplesheet})
	>&2 echo "## "$(date)",${0},${HOSTNAME},${SCRIPTCALL}" >> $SAMPLESHEETFOLDER/"${HOSTNAME}"_all_generated.log
fi
echo "## "$(date)" ## $0 ## Creating rundir/jobsdir"

jobsDir=$runDir/jobs

mkdir -p $jobsDir

#scriptHome=/groups/umcg-oncogenetics/tmp04/git/molgenis-c5-TumorNormal/

>&2 echo  "## "$(date)" ## $0 ## progname="$0
>&2 echo  "## "$(date)" ## $0 ## workflowdir="$workflowDir
>&2 echo "## "$(date)" ## $0 ## workflowBase="$workflowBase
>&2 echo  "## "$(date)" ## $0 ## samplesheet="$samplesheet
#echo  "## "$(date)" ## $0 ## group="$group
#echo  "## "$(date)" ## $0 ## tmp="$tmp
#echo  "## "$(date)" ## $0 ## scriptHome="$scriptHome
>&2 echo  "## "$(date)" ## $0 ## targetsList="$targetsList

#perl -wpe 's/group,gcc/group,'$group'/g' $workflowDir/parameters.csv > $workflowDir/.parameters.tmp.csv
#perl -wpe 's/group,gcc/group,'$group'/g' $siteParam > $workflowDir/.parameters.site.tmp.csv

#add additional parameters and convert samplesheets to molgenis-compute format
>&2 echo  "## "$(date)" ## $0 ## append targetsList parameter '$targetsList'"
>&2 echo "targetsList,"$targetsList>>$workflowDir/.parameters.tmp.csv
>&2 echo "projectSampleSheet,${runDir}"/$(basename "${samplesheet}")>>$workflowDir/.parameters.tmp.csv
>&2 echo  "## "$(date)" ## $0 ## Convert parametersheet"
perl $workflowDir/convertParametersGitToMolgenis.pl $workflowDir/.parameters.tmp.csv > $workflowDir/.parameters.molgenis.csv
perl $workflowDir/convertParametersGitToMolgenis.pl $workflowDir/.parameters.site.tmp.csv > $workflowDir/.parameters.site.molgenis.csv

>&2 echo  "## "$(date)" ## $0 ## Convert samplesheet"
perl -wpe 's!projectNameHere!'$projectname'!g' $samplesheet > $samplesheet.tmp.csv
perl $workflowDir/ValidateSampleSheet.pl $samplesheet

cp $samplesheet.tmp.csv $runDir/$(basename $samplesheet)
cp $workflowDir/.parameters.tmp.csv $runDir/parameters.csv
#echo "$SCRIPTCALL" >>
backend="slurm"
molgenisBase=$workflowDir/templates/compute/v15.04.1/$backend/

if [ $(find $jobsDir -iname *.finished| head -1|wc -l | tee /dev/stderr) -ne 0 ] && [ -e $(find $jobsDir -iname *.finished| head -1) ]; then
	>&2 echo "## "$(date)" ## $0 ## Already generated removing finished."
	rm $jobsDir/*.finished
fi

#git info tracking
>&2 echo "## "$(date)" ## $0 ## Generation info"

(
	if which git &>/dev/null; then
		>&2 echo "## "$(date)" ## $0 ## Command `git` present"
	else
		>&2 echo "## "$(date)" ## $0 ## Commmand `git` not present, trying module load."
		ml git
	fi
	echo
	echo "## "$(date)" ## $0 ## Generation info"
	echo
	echo "### Version info"
	echo
	echo -n "This is generated based on the git "
	git log | head -n 1
	echo ". Althought this is software in developent and also the next commit should also be considered."
        echo
	echo "### Branch info"
	echo
	git branch
	echo
	echo "### Used software versions"
	echo
	echo " The used software versions are shown below. Easybuild software \
deployment/versioning was used so the versions are named as as \
Software/version[-easybuild toolchain][-suffix]. \
\`easybuild toolchain\` : collection of basic unix tools (gcc \
compiler / devtools /etc ).\`suffix\`: mainly to indicate a \
specific language version the tool uses."
	echo
	grep "^[a-zA-Z].*Mod"  $workflowDir/.parameters.site.tmp.csv | perl -wpe 's/.*Mod,/ - /g'
) > $runDir/generation.log


>&2 echo  "## "$(date)" ## $0 ## Generate scripts"
$mlCmd
#module load molgenis_compute/v5_20140522
(
	echo 'set -e; set -x'
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
	 -footer $molgenisBase/footer.ftl "1>/dev/null"

	echo -e "perl RemoveDuplicatesCompute.pl $jobsDir/*.sh &>/dev/null && perl -i -wpe 's/#SBATCH --partition=duo-pro/#SBATCH --partition=duo-pro\n#SBATCH --qos=leftover/;s/#SBATCH --partition=duo-dev/#SBATCH --partition=duo-dev\n#SBATCH --qos=leftover/' $jobsDir/*.sh"
	echo -e "echo -e bash $jobsDir/submit.sh"
)| tee .RunWorkFlowGeneration.sh
#GenerateScripts2.sh

# -header $MC_HOME/templates/pbs/header.ftl \
# -submit $MC_HOME/templates/pbs/submit.ftl \
# -footer $MC_HOME/templates/pbs/footer.ftl 

#what does runid do?
# -runid 02 \
# -header $molgenisBase/templates/pbs/header.ftl \
# -submit $molgenisBase/templates/pbs/submit.ftl \
# -footer $molgenisBase/templates/pbs/footer.ftl 

#rm $samplesheet.tmp.csv
