#MOLGENIS walltime=23:59:00 mem=6gb ppn=1 nodes=1 


#string project
#string stage
#string convadingMod
#string tableToXlsxMod

#string convadingDir
#string markDuplicatesDir
#string ampliconsBed
#string targetsList
set -x
set -e

alloutputsexist \
	${convadingDir}

getFile ${markDuplicatesDir}

echo "## "$(date)" ##  $0 Started "
if [ ${targetsList} == ${ampliconsBed} ]; then 
	#generic mode on targetslist
	(
		mkdir -p "${convadingDir}"
		${stage} ${convadingMod}
		grep -v '^@' ${targetsList} | perl -wlane 'print join("\t",($F[0],$F[1]-1,$F[2],$.));' >  ${convadingDir}/targets.bed
		CoNVaDING.pl StartWithBam \
			 -inputDir ${markDuplicatesDir} \
			 -outputDir ${convadingDir} \
			 -controlsDir ${convadingDir} \
			 -bed ${convadingDir}/targets.bed \
			 -useSampleAsControl \
			 -samtoolsdepthmaxcov 40000
	)
else
	#iontorrent mode on ampliconsBed
        (
		mkdir -p "${convadingDir}"
		${stage} ${convadingMod}

		CoNVaDING.pl StartWithBam \
			 -inputDir ${markDuplicatesDir} \
			 -outputDir ${convadingDir} \
			 -controlsDir ${convadingDir} \
			 -bed ${ampliconsBed} \
			 -useSampleAsControl \
			 -ampliconcov 0.85 \
			 -samtoolsdepthmaxcov 40000
	)

fi
(	
	${stage} ${tableToXlsxMod}

	(cd ${convadingDir} 
		(headnormtxt="$(ls ${convadingDir}*.normalized.coverage.txt| head -n 1)"
		for s in $(seq 1 12); do 
			echo  "merge."$(head -n 1 "$headnormtxt" |cut -f $s)".txt"
			echo "paste <(cut -f 1-4 "$headnormtxt" ) "$(for i in $(ls $(dirname "$headnormtxt")/*.txt); do echo -n " <(echo  $(basename $i) | perl -wpe 's/.normalized.coverage.txt//g' && cut -f $s $i | tail -n+2)" ; done; echo )| bash \
			 > $(dirname $headnormtxt)_merge.$(head -n 1 "$headnormtxt" | cut -f $s).txt;
		done && \
		tableToXlsxAsStrings.pl \\t $(dirname $headnormtxt)_merge.*.txt;
		zip -ru $(dirname $headnormtxt)_merge$(date --date=Yesterday --rfc-3339=date).zip $(dirname $headnormtxt)_merge.*.xlsx)
	)
)
if [ ${targetsList} != ${ampliconsBed} ]; then
        #Special request region EFGR exon 19 for iontorrent

	(
	        ${stage} ${convadingMod}
	
		mkdir -p $(dirname ${convadingDir})/$(basename ${convadingDir})_e19/
		echo -e "7\t55242487\t55242563\tEFGRe19" > $(dirname ${convadingDir})/$(basename ${convadingDir})_e19/e19.bed
	
		#yeah it caps at 50%
		CoNVaDING.pl StartWithBam \
		         -inputDir ${markDuplicatesDir} \
		         -outputDir $(dirname ${convadingDir})/$(basename ${convadingDir})_e19/ \
		         -controlsDir $(dirname ${convadingDir})/$(basename ${convadingDir})_e19 \
		         -bed $(dirname ${convadingDir})/$(basename ${convadingDir})_e19/e19.bed \
		         -useSampleAsControl \
		         -ampliconcov 0.50 \
			 -samtoolsdepthmaxcov 40000
	
	
	)
	(	
		${stage} ${tableToXlsxMod}
	
		(
			cd $(dirname ${convadingDir})/$(basename ${convadingDir})_e19/
		        (headnormtxt="$(ls $(dirname ${convadingDir})/$(basename ${convadingDir})_e19/*.normalized.coverage.txt| head -n 1)"
		        for s in $(seq 1 12); do
				echo  "merge."$(head -n 1 "$headnormtxt" |cut -f $s)".txt"
				echo "paste <(cut -f 1-4 "$headnormtxt" ) "$(for i in $(ls $(dirname "$headnormtxt")/*.txt); do echo -n " <(echo  $(basename $i) | perl -wpe 's/.normalized.coverage.txt//g' && cut -f $s $i | tail -n+2)" ; done; echo )| bash \
				 > $(dirname $headnormtxt)_merge.$(head -n 1 "$headnormtxt" | cut -f $s).txt;
			done && \
		        tableToXlsxAsStrings.pl \\t $(dirname $headnormtxt)_merge.*.txt;
		        zip -ru $(dirname $headnormtxt)_merge$(date --date=Yesterday --rfc-3339=date).zip $(dirname $headnormtxt)_merge.*.xlsx)
		)
	)
fi
putFile ${convadingDir}

echo "## "$(date)" ##  $0 Done "

