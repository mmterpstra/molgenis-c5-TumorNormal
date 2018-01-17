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

set -x -e -o pipefail

echo "## "$(date)" ##  $0 Started "
	
if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	getFile ${reads1FqGz}
	mkdir -p "$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!')"
	cp ${reads1FqGz} "$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})"
	cp ${reads1FqGz}.md5 "$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})".md5

	#count lines for filtering
	gzip -dc ${reads1FqGz} | wc -l > "$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})".linecount.log
	
	#might go wrong if done twice in fast sucession best is to run this local & not parallel.
	perl -i.bak -wpe 's!'${reads1FqGz}'!'"$(dirname ${reads1FqGz} | perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})"'!g' ${rundir}/../*.input.csv
	
	SampleSheetAddVal.pl "${rundir}"/../*.input.csv project=projectname,sampleName=sample1,count=1000000 > "${rundir}"/../*.input.tmp.csv
	mv "${rundir}"/../*.input.tmp.csv "${rundir}"/../*.input.csv
	
	putFile "$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})"
	putFile "$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})".md5
	putFile "$(dirname ${reads1FqGz}| perl -wpe 's!prm\d\d/data/raw/!tmp04/raw/!g')/$(basename ${reads1FqGz})".linecount.log
else
	echo "Not implemented"
	exit 1
fi

echo "## "$(date)" ##  $0 Done "
