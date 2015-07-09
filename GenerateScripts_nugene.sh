#!bin/bash


#main thing to remember when working with molgenis "/full/paths" ALWAYS!
#here some parameters for customisation
workflowdir=$(readlink -f $(dirname $0))
samplesheet=$(readlink -f $1)
projectname=$2
targetsList=$(readlink -f $3)

#ugly way of detecting inheritance
group=$(ls -alh $(pwd)| perl -wpe 's/ +/ /g' | cut -f 4 -d " "| tail -n1)
tmp="tmp01"
#projectname="rnaseq/development/rnaGatkHaplotypeCaller/results/test_short/"

runDir=/gcc/groups/${group}/${tmp}/projects/$projectname/jobs
mkdir -p $runDir


#projectname,/rnaseq/development/rnaGatkHaplotypeCaller/results/$projectname
#maybe sync projectname in samplesheet
echo "use: samplesheet projectname targetsList"


scriptHome=/gcc/groups/oncogenetics/prm02/data/mytools/molgenis-compute-core-1.0.0-SNAPSHOT/workflows/molgenis-c5-TumorNormal/

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




cp $samplesheet.tmp.csv /gcc/groups/${group}/${tmp}/projects/$projectname/$(basename $samplesheet)
cp $workflowdir/parameters.tmp.csv /gcc/groups/${group}/${tmp}/projects/$projectname/parameters.csv



echo "Generate scripts"
#module load molgenis_compute/v5_20140522
module load jdk/1.7.0_51
molgenisBase=/gcc/groups/gcc/tmp01/projects/rnaseq/development/rnaGatkHaplotypeCaller/scripts/molgenis-compute-core-1.0.0-SNAPSHOT

bash ${molgenisBase}/molgenis_compute.sh \
 --generate \
 -p $workflowdir/parameters.molgenis.csv \
 -p $samplesheet.tmp.csv \
 -p $workflowdir/scatter_id.csv \
 -w $workflowdir/workflow_nugene.csv \
 --backend pbs \
 --weave \
 -rundir $runDir \
 -header $molgenisBase/templates/pbs/header.ftl \
 -submit $molgenisBase/templates/pbs/submit.ftl \
 -footer $molgenisBase/templates/pbs/footer.ftl 

# -header $MC_HOME/templates/pbs/header.ftl \
# -submit $MC_HOME/templates/pbs/submit.ftl \
# -footer $MC_HOME/templates/pbs/footer.ftl 

#what does runid do?
# -runid 02 \
# -header $molgenisBase/templates/pbs/header.ftl \
# -submit $molgenisBase/templates/pbs/submit.ftl \
# -footer $molgenisBase/templates/pbs/footer.ftl 

#rm $samplesheet.tmp.csv
