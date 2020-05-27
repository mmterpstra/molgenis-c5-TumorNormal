#MOLGENIS nodes=1 ppn=1 mem=35gb walltime=60:00:00

#string project

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string fusioncatcherMod
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string fusioncatcherDir
#string fusioncatcherDataDir
#string fusioncatcherOutDir
#string fusioncatcherTsv

#string nTreads
#list reads1FqGz,reads2FqGz,reads1FqGzOriginal,reads2FqGzOriginal

echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${fusioncatcherTsv} \
	${fusioncatcherOutDir}

#getFile functions

getFile ${onekgGenomeFasta}

#Load modules
ml TableToXlsx
${stage} ${fusioncatcherMod}

#check modules
${checkStage}

set -x
set -e

mkdir -p ${fusioncatcherDir}
mkdir -p ${fusioncatcherOutDir}
#lets hope this sorting works:
#paste <(printf '%s\n' ${reads1FqGz[@]}| sort -u) <(printf '%s\n' ${reads2FqGz[@]}| sort -u) | perl -wne 'chomp;s/\s/,/g;$_=",".$_ if($. != 1);print $_;'

if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	#this is not pe!
	mkdir -p $(dirname ${fusioncatcherTsv})
	echo "This is not PE sequencing" > ${fusioncatcherTsv}
else
	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
	input=$(paste <(printf '%s\n' ${reads1FqGz[@]}| sort -u) <(printf '%s\n' ${reads2FqGz[@]}| sort -u) | perl -wne 'chomp;s/\s/,/g;$_=",".$_ if($. != 1);print $_;')

	python $EBROOTFUSIONCATCHER/bin/fusioncatcher.py --input=$input --output=${fusioncatcherOutDir} --data=${fusioncatcherDataDir} --threads=1 --visualization-sam --skip-conversion-grch37 --paranoid-sensitive --keep --keep-preliminary --reads-preliminary-fusions

	tableToXlsxAsStrings.pl \\t ${fusioncatcherTsv}
fi

putFile ${fusioncatcherTsv}
putFile ${fusioncatcherOutDir}

echo "## "$(date)" ##  $0 Done "
