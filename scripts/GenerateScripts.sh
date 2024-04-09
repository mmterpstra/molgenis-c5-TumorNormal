#!/bin/bash

set -ex
set -u
set -o pipefail

ml purge 

SCRIPTCALL="$0 $@"
>&2 echo "## "$(date)" ## $0 ## Called with call '${SCRIPTCALL}'"
>&2 echo "## "$(date)" ## $0 ## Use:$0 [none|wgs|exome|exomele150|exomegt150|rna|nugene|nugrna|prepiont|iont|withpoly|lexo|lpwgs|lpwgsle150|lpwgsgt150] samplesheet projectname targetsList <nugeneProbebed/iontAmpliconBed>"
>&2 echo "## "$(date)" ## $0 ##     [none|exome|rna|nugene|nugrna|iont|withpoly|lexo]   "
>&2 echo "## "$(date)" ## $0 ##                    Application to use for sequencing."
>&2 echo "## "$(date)" ## $0 ##     samplesheet    Csv file describing the fastq and samples to be analysed."
>&2 echo "## "$(date)" ## $0 ##     projectname    Name to tag the project: this decides the header in your batchfiles and location to generate the jobs files."
>&2 echo "## "$(date)" ## $0 ##     targetsList    Interval_list formatted file describing the target regions to report mutations in and near these regions."
>&2 echo "## "$(date)" ## $0 ##     <nugeneProbebed/iontAmpliconBed>"
>&2 echo "## "$(date)" ## $0 ##                    Specific files for special workflow."

backend="slurm"
#javaver="1.8.0_74"
#computever="v16.04.1"
computever="v17.08.1"
#computever="v19.01.1"; #this version aint compatible
#mlCmd="module load Molgenis-Compute/${computever}-Java-${javaver}"
mlCmd="module load Molgenis-Compute/v17.08.1-Java-8-LTS"
	###module load Molgenis-Compute/v15.11.1-Java-1.8.0_45



	#main thing to remember when working with molgenis "/full/paths" ALWAYS!
	#here some parameters for customisation

#assumes workflowdir/scripts/GenerateScripts
workflowDir=$(dirname $(dirname $(which $0 2> /dev/null) 2>/dev/null || readlink -f $(dirname $0)))

samplesheet=$(readlink -f $2)

projectname=$3

(
	if [ -e $4 ];then
		targetsList=$(readlink -f $4)
	else
		if [ $4 == "none" ] ; then
			>&2 echo  "## "$(date)" ## $0 ## No intervallist"
			targetsList=""
		fi
	fi

	>&2 echo "## "$(date)" ## $0 ## Running on host '"$HOSTNAME"'."

	if [[ "$HOSTNAME" =~ gearshift ]] ;then
                >&2 echo "## "$(date)" ## $0 ## Setting peregrine molgenis variables"
                runDir=/groups/umcg-pmb/tmp01/umcg-mterpstra/projects/$projectname
                siteParam=$workflowDir/parameters/gearshift.siteconfig.csv

                #partitionFix='perl -i -wpe "s/^#SBATCH\ --partition=ll$/#SBATCH\ --partition=nodes/g"'
	elif [[ "$HOSTNAME" =~ pg-interactive* ]] ;then
		>&2 echo "## "$(date)" ## $0 ## Setting peregrine molgenis variables"
		runDir=/scratch/$USER/projects/$projectname
		siteParam=$workflowDir/parameters/peregrine.siteconfig.csv

		#partitionFix='perl -i -wpe "s/^#SBATCH\ --partition=ll$/#SBATCH\ --partition=nodes/g"'
	elif [ $HOSTNAME == "peregrine.hpc.rug.nl" ];then
	        >&2 echo "## "$(date)" ## $0 ## Setting peregrine molgenis variables"
	        runDir=/scratch/$USER/projects/$projectname
	        siteParam=$workflowDir/parameters/peregrine.siteconfig.csv
	
	        #partitionFix='perl -i -wpe "s/^#SBATCH\ --partition=ll$/#SBATCH\ --partition=nodes/g"'
	elif [ $HOSTNAME == "pg-login" ];then
	        >&2 echo "## "$(date)" ## $0 ## Setting peregrine molgenis variables"
		runDir=/scratch/$USER/projects/$projectname
	        siteParam=$workflowDir/parameters/peregrine.siteconfig.csv
		cp $siteParam $runDir/.parameters.site.tmp.csv
		cp $workflowDir/parameters/parameters.csv  $runDir/.parameters.tmp.csv

	elif [ $HOSTNAME == "calculon" ];then
	        >&2 echo "## "$(date)" ## $0 ## Setting calculon molgenis variables"
		group=$(ls -alh $(pwd)| perl -wpe 's/ +/ /g' | cut -f 4 -d " "| tail -n1)
		tmp="tmp04"
	
		runDir=/groups/${group}/${tmp}/projects/$projectname
	        siteParam=$workflowDir/parameters/umcg.siteconfig.csv
	
		mlCmd='module load Molgenis-Compute/v16.04.1-Java-1.8.0_45'
	
		perl -wpe 's/group,gcc/group,'$group'/g' $workflowDirparameters//parameters.csv > $workflowDir/.parameters.tmp.csv
		perl -wpe 's/group,gcc/group,'$group'/g' $siteParam > $workflowDir/.parameters.site.tmp.csv
	elif [[ "$HOSTNAME" =~ travis-worker-* ]] ; then
		>&2 echo  "## "$(date)" ## $0 ## Setting testing molgenis variables."

		mlCmd="module load Molgenis-Compute"
		runDir=/home/$USER/projects/$projectname
	        siteParam=$workflowDir/parameters/peregrine.siteconfig.csv

	elif [[ "$HOSTNAME" =~ testing-* ]] || [[ "$HOSTNAME" =~ *worker-org* ]] ; then

	        >&2 echo "## "$(date)" ## $0 ## Setting testing molgenis variables (2)"

	        mlCmd="module load Molgenis-Compute"
	        runDir=/home/$USER/projects/$projectname
	        siteParam=$workflowDir/parameters/peregrine.siteconfig.csv


	else
		>&2 echo "## "$(date)" ## $0 ## Setting default variables, beause hostname not recognised. You can edit this script to put in your own hostname or edit existing ones."
		
		mlCmd="module load Molgenis-Compute"
		runDir=/home/$USER/projects/$projectname
		siteParam=$workflowDir/parameters/peregrine.siteconfig.csv

	fi
	
	#copying the files to the project folder
	mkdir -p $runDir/
	cp $siteParam $runDir/.parameters.site.tmp.csv
	cp $workflowDir/parameters/parameters.csv  $runDir/.parameters.tmp.csv

	
	>&2 echo "## "$(date)" ## $0 ## Running with workflow '"$1"'."

	if [ $1 == "none" ];then
		>&2 echo  "## "$(date)" ## $0 ## Exiting cause no workflow specified"
	        exit 1
	elif [ $1 == "wgs" ];then
		>&2 echo  "## "$(date)" ## $0 ## Using Exome-seq cause no working wgs workflow"
		>&2 echo  "## "$(date)" ## $0 ## Using Exome-seq workflow"
		workflowBase="workflow_grch38_wgs.csv"
		cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
	elif [ $1 == "exome" ];then
		>&2 echo  "## "$(date)" ## $0 ## Using Exome-seq workflow"
                workflowBase="workflow_grch38.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
        elif [ $1 == "exomele150" ];then
                >&2 echo  "## "$(date)" ## $0 ## Using Exome-seq experimental le150 workflow"
                workflowBase="workflow_grch38_le150.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
        elif [ $1 == "exomegt150" ];then
                >&2 echo  "## "$(date)" ## $0 ## Using Exome-seq experimental gt150 workflow"
                workflowBase="workflow_grch38_gt150.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
	elif [ $1 == "rna" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using RNA-seq workflow"
	        workflowBase="workflow_rnaseq_star.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
	elif [ $1 == "rnaumi" ];then
		>&2 echo  "## "$(date)" ## $0 ## Using RNA-seq umi workflow"
		workflowBase="workflow_rnaseq_star_umi.csv"
		cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
	elif [ $1 == "lexorat" ]; then
		>&2 echo  "## "$(date)" ## $0 ## Using Lexogen Rat workflow"
		workflowBase="workflow_lexogenrnarat.csv"
		cat  $workflowDir/parameters/rat_parameters.csv >>  $runDir/.parameters.site.tmp.csv
	elif [ $1 == "nugene" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using nugene workflow"
	        workflowBase="workflow_nugene.csv"
	        nugeneProbeBed=$5
		cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
	        perl -i.bak  -wpe 's!(probeBed,).*!$1'"$nugeneProbeBed"'!g' $runDir/.parameters.site.tmp.csv
	
	elif [ $1 == "nuginc" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using nugene advised workflow"
	        workflowBase="workflow_nugeneinc.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
                
	elif [ $1 == "nugincbybed" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using nugene advised workflow"
	        workflowBase="workflow_nugeneinctrimbybed.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv

	elif [ $1 == "nugrna" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using Nugene RNA workflow"
	        workflowBase="workflow_nugenerna.csv"
		nugeneRnaProbeBed=$5
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
	
	        perl -i.bak  -wpe 's!(probeRnaBed,).*!$1'"$nugeneRnaProbeBed"'!g' $runDir/.parameters.site.tmp.csv
	elif [ $1 == "nugrnastar" ];then
		>&2 echo  "## "$(date)" ## $0 ## Using Nugene RNA STAR workflow"
		workflowBase="workflow_nugenerna_star.csv"
		nugeneRnaProbeBed=$5
		cat $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv

		perl -i.bak  -wpe 's!(probeRnaBed,).*!$1'"$nugeneRnaProbeBed"'!g' $runDir/.parameters.site.tmp.csv

	elif [ $1 == "iont" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using iontorrent workflow"
	        workflowBase="workflow_iont_scat.csv"
                cat $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		ampliconsBed=$5
		perl -i.bak  -wpe 's!(ampliconsBed,).*!$1'"$ampliconsBed"'!g' $runDir/.parameters.site.tmp.csv
		
	elif [ $1 == "umi" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using umi Exome-seq workflow"
	        #workflowBase="workflow.csv"
		#cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		>&2 echo  "## "$(date)" ## $0 ## Using Exome-seq workflow"
                workflowBase="workflow_umi.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
                
	elif [ $1 == "umitwist" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using umi Exome-seq workflow"
	        #workflowBase="workflow.csv"
		#cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		>&2 echo  "## "$(date)" ## $0 ## Using Twist exome umi workflow"
                workflowBase="workflow_umi_twist.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
                
	elif [ $1 == "umitwistlpwgs" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using umi Exome-seq workflow"
	        #workflowBase="workflow.csv"
		#cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		>&2 echo  "## "$(date)" ## $0 ## Using Twist exome umi workflow"
                workflowBase="workflow_umi_twist_lpwgs.csv"
                cat  $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
                
	elif [ $1 == "prepiont" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using iontorrent bamtofastq workflow"
	        workflowBase="workflow_prepiont.csv"
	        if [ $HOSTNAME == "peregrine.hpc.rug.nl" ] ; then 
			backend="slurm"
		else
			backend="localhost"
		fi
                cat $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		
		ampliconsBed=$5
		perl -i.bak  -wpe 's!(ampliconsBed,).*!$1'"$ampliconsBed"'!g' $runDir/.parameters.site.tmp.csv
		
	elif [ $1 == "withpoly" ];then
	        >&2 echo  "## "$(date)" ## $0 ## Using Exome-seq with polymorfic  workflow"
	        workflowBase="workflow_withPolymorfic.csv"
                cat $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
                
	elif [ $1 == "lexo" ]; then
		>&2 echo  "## "$(date)" ## $0 ## Using Lexogen stranded 3prime mRNA-seq workflow"
		workflowBase="workflow_lexogenrna.csv"
		cat $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		
	elif [ $1 == "lpwgs" ]; then
		>&2 echo  "## "$(date)" ## $0 ## Using Low pass wgs protocol aka only produce bams/qc tables"
		workflowBase="workflow_lpwgs.csv"
		cat $workflowDir/parameters/human_grch38_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		
	elif [ $1 == "lpwgsle150" ]; then
		>&2 echo  "## "$(date)" ## $0 ## Using Low pass wgs protocol aka only produce bams/qc tables"
		workflowBase="workflow_lpwgs_le150.csv"
		cat  $workflowDir/human_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		
	elif [ $1 == "lpwgsgt150" ]; then
		>&2 echo  "## "$(date)" ## $0 ## Using Low pass wgs protocol aka only produce bams/qc tables"
		workflowBase="workflow_lpwgs_gt150.csv"
		cat  $workflowDir/human_parameters.csv >>  $runDir/.parameters.site.tmp.csv
		
	else
	    	>&2 echo  "## "$(date)" ## $0 ## Error: No valid Seqtype in input" && exit 1
	fi


	#backup samplesheets somewhere
	if [ -z "${SAMPLESHEETFOLDER+x}" ]; then
		SAMPLESHEETFOLDER="$(dirname $0)/samplesheets/"
	fi
	if [ -d $SAMPLESHEETFOLDER ]; then
		>&2 echo "## "$(date)" ## $0 ## Copying samplesheet to samplesheets folder '$SAMPLESHEETFOLDER'"
		if [ -e  "$SAMPLESHEETFOLDER/${HOSTNAME}_"$(basename ${samplesheet}) ]; then 
			if cmp -s "$SAMPLESHEETFOLDER/${HOSTNAME}_""$(basename ${samplesheet})" "${samplesheet}"; then
				 >&2 echo "##  Samplesheet files are the same do noting"
			else
				 cp -v "${samplesheet}" "$SAMPLESHEETFOLDER/${HOSTNAME}_""$(date --iso)""_""$(basename ${samplesheet})"
			fi

		else 
			cp -v "${samplesheet}" "$SAMPLESHEETFOLDER/${HOSTNAME}_"$(basename ${samplesheet})
		fi
		>&2 echo "## "$(date)",${0},${HOSTNAME},bash ${SCRIPTCALL}" >> $SAMPLESHEETFOLDER/"${HOSTNAME}"_all_generated.log
		>&2 echo "## "$(date)",${0},${HOSTNAME},bash ${SCRIPTCALL},"$((git log -1 || echo "$(pwd)" "$(date)") | head -n 1 ) >> "$SAMPLESHEETFOLDER""/""${HOSTNAME}""_all_generated.log"
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
	>&2 echo "targetsList,"$targetsList>>$runDir/.parameters.tmp.csv
	>&2 echo "projectSampleSheet,${runDir}"/$(basename "${samplesheet}")>>$runDir/.parameters.tmp.csv
	>&2 echo  "## "$(date)" ## $0 ## Convert parametersheet"
	perl $workflowDir/scripts/convertParametersGitToMolgenis.pl $runDir/.parameters.tmp.csv > $runDir/.parameters.molgenis.csv
	perl $workflowDir/scripts/convertParametersGitToMolgenis.pl $runDir/.parameters.site.tmp.csv > $runDir/.parameters.site.molgenis.csv

	>&2 echo  "## "$(date)" ## $0 ## Convert samplesheet"
	perl -wpe 's!projectNameHere!'$projectname'!g' "$samplesheet" > "${samplesheet}"".tmp.csv"
	if [ $1 != "prepiont" ];then
		echo "Validating samplesheet"
		perl $workflowDir/scripts/ValidateSampleSheet.pl "$samplesheet" 
		perl $workflowDir/scripts/SampleSheetTool.pl valid "$samplesheet"

	fi
	cp "$samplesheet.tmp.csv" "$runDir/""$(basename $samplesheet .csv)"".input.csv"
	cp "$runDir/.parameters.tmp.csv" "$runDir/parameters.csv"
	#echo "$SCRIPTCALL" >>
	molgenisBase=$workflowDir/templates/compute/${computever}/$backend/
	
	#git info tracking
	>&2 echo "## "$(date)" ## $0 ## Generation info"
	
	#if not present create file
	touch "$runDir/generation.log"	
	

	#block of text to append to file
	(
		if which git &>/dev/null; then
			>&2 echo "## "$(date)" ## $0 ## Command 'git' present"
			if git status &>dev/null; then
                		GITCMD='git log -1'
			else
				>&2 echo "## "$(date)" ## $0 ## Command 'git' present but no git repo..."
				GITCMD='echo "$(pwd) $(date)"'
			fi
		else
			>&2 echo "## "$(date)" ## $0 ## Commmand 'git' not present, trying module load."
			ml git
			if which git &>/dev/null; then
				>&2 echo "## "$(date)" ## $0 ## Command 'git' present after 'ml git'"
				if git status &>dev/null; then
					GITCMD='git log -1'
				else
					>&2 echo "## "$(date)" ## $0 ## Command 'git' present but no git repo..."
					GITCMD='echo "$(pwd) $(date)"'
				fi
			else
				>&2 echo "## "$(date)" ## $0 ## Command 'git' not present after 'ml git'"
				GITCMD='echo "$(pwd) $(date)"'
			fi
		
		fi


		echo
		echo "## "$(date)" # $0 # Generation info"
		echo
		echo "### Version info"
		echo
		echo -n "This is generated based on the git or path+date '"
		$GITCMD | head -n 1
		echo "' with command '"$SCRIPTCALL"'. Althought this is software in development and also the next commit should also be considered."

		
		module load Graphviz || true
		
		if [ git branch &>/dev/null ]; then
			echo
			echo "### Branch info"
			echo
			git branch
		fi 
		
		mlGraphvizCmd="true"
		if module load Graphviz; then 
			mlGraphvizCmd="module load Graphviz"
			which dot &>/dev/null || exit 1
		fi	

		if which dot &>/dev/null; then
			>&2 echo "## "$(date)" ## $0 ## Command 'dot' present"
			echo
			echo "### Workflow image"
			echo 
			echo "workflow used as shown below"
			echo
			echo -n '<img src="data:image/svg+xml;base64,'"$(python3 ${workflowDir}/scripts/workflow2dot.py $workflowDir/workflows/$workflowBase | ($mlGraphvizCmd &&  dot -Tsvg /dev/stdin) | base64)"'"\>'
		else
			>&2 echo "## "$(date)" ## $0 ## Commmand 'dot' not present."
			echo '<!-- Commmand `dot` not present. so no workflow image is generated -->'
		fi
		
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
		grep "^[a-zA-Z].*Mod"  ${runDir}/.parameters.site.tmp.csv | perl -wpe 's/.*Mod,/ - /g'
		echo
		echo "### Used host for acknowledgements"
		echo
		echo "The used host is $HOSTNAME.

Relevant method of acknowledgement if host looks like "calculon.hpc.rug.nl, boxy.hpc.rug.nl, umcg.hpc.rug.nl or gearshift.hpc.rug.nl": 

> This cluster is offered to you by the Genomics Coordination Center (UMCG, Groningen, NL) and its partners & sponsors.
> Please acknowledge us in your scientific publications as follows:
>  'We thank the UMCG Genomics Coordination center, the UG Center for Information Technology
>  and their sponsors BBMRI-NL & TarGet for storage and compute infrastructure.'
> from old calculon.hpc.rug.nl:/etc/motd 

Relevant method	of acknowledgement if host looks like "peregrine.hpc.rug.nl or pg-interactive.hpc.rug.nl":

> If you want to acknowledge the use of the Peregrine cluster and the support of the CIT in your papers you can use the following acknowledgement:
>    'We would like to thank the Center for Information Technology of the University of Groningen for their support
>    and for providing access to the Peregrine high performance computing cluster.'
> from https://wiki.hpc.rug.nl/peregrine/introduction/scientific_output

"
                echo "### Generation tries"
		echo
		echo -n 'Here goes nothing nr 1+' 
		grep -c  'Generation info' $runDir/generation.log
		echo
		echo '------------------'
		echo '------------------'
		echo
		
	) >> $runDir/generation.log
	
	
	>&2 echo  "## "$(date)" ## $0 ## Generate scripts"
	$mlCmd
	#module load molgenis_compute/v5_20140522
	(
		echo 'set -e; set -x'
		echo $mlCmd
		#echo $partitionFix $jobsDir'/*.sh'
		echo "EBROOTCOMPUTEMINC5MINTUMORNORMAL=\"\""
		echo "if [ -z \"\$EBROOTCOMPUTEMINC5MINTUMORNORMAL\" ]; then cd \"\$EBROOTCOMPUTEMINC5MINTUMORNORMAL\"; else \"No easybuild module assume in (git) project folder\"; fi" 
		echo bash ${EBROOTMOLGENISMINCOMPUTE}/molgenis_compute.sh \
		 --generate \
		 -p $runDir/.parameters.molgenis.csv \
		 -p $runDir/.parameters.site.molgenis.csv \
		 -p $samplesheet.tmp.csv \
		 -p $workflowDir/parameters/scatter_id.csv \
		 -w $workflowDir/workflows/$workflowBase \
		 --backend ${backend} \
		 --weave \
		 -rundir $jobsDir \
		 -header $molgenisBase/header.ftl \
		 -submit $molgenisBase/submit.ftl \
		 -footer $molgenisBase/footer.ftl "1>/dev/null"
	
		echo -e "perl scripts/RemoveDuplicatesCompute.pl $jobsDir/*.sh &>/dev/null && perl -i -wpe 's/#SBATCH --partition=duo-pro/#SBATCH --partition=duo-pro\n#SBATCH --qos=leftover/;s/#SBATCH --partition=duo-dev/#SBATCH --partition=duo-dev\n#SBATCH --qos=leftover/' $jobsDir/*.sh"
		echo -e "echo -e bash $jobsDir/submit.sh"
	#)| tee .RunWorkFlowGeneration.sh
	) > .RunWorkFlowGeneration.sh
	if [ $(find $jobsDir -iname '*.finished'| head -1|wc -l | tee /dev/stderr) -ne 0 ] && [ -e $(find $jobsDir -iname *.finished| head -1) ]; then
	        >&2 echo "## "$(date)" ## $0 ## Already generated removing finished."
	       	#echo 'rm $jobsDir/*.finished' >> .RunWorkFlowGeneration.sh
	fi

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
) &>/dev/stdout| tail -n 200
