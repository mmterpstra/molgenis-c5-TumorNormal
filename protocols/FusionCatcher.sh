#MOLGENIS nodes=1 ppn=1 mem=35gb walltime=40:00:00

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
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${fusioncatcherTsv}
	${fusioncatcherOutDir}
 
#getFile functions

getFile ${onekgGenomeFasta}

#Load modules
${stage} ${fusioncatcherMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${fusioncatcherDir}

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

	python $EBROOTFUSIONCATCHER/bin/fusioncatcher.py --input=$input --output=${fusioncatcherOutDir} --data=${fusioncatcherDataDir} --threads=1 --visualization-sam --skip-conversion-grch37 --reads-preliminary-fusions
fi

putFile ${fusioncatcherTsv}
putFile ${fusioncatcherOutDir}

echo "## "$(date)" ##  $0 Done "
