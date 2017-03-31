#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#string project
###string rundir

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string group
#string checkStage
#string picardMod
#string projectDir
#string bamFiles
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal
#string sampleName

echo -e "test ${reads1FqGz} ${reads2FqGz} 1: "

${stage} ${picardMod}
${checkStage}

set -x
set -e

echo "## "$(date)" ##  $0 Started "
	
if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	getFile ${reads1FqGz}
	mkdir -p $(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!')
	cp ${reads1FqGz} $(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})
	cp ${reads1FqGz}.md5 $(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz}).md5
	perl -i.bak -wpe 's!'${reads1FqGz}'!'$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})'!g' ${rundir}/../*.input.csv
	putFile $(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp02/raw/!g')/$(basename ${reads1FqGz})
	putFile $(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp02/raw/!g')/$(basename ${reads1FqGz}).md5
else
	echo "Not implemented"
	exit 1
fi

echo "## "$(date)" ##  $0 Done "
