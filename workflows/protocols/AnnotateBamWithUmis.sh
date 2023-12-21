#MOLGENIS walltime=23:59:00 mem=17gb nodes=1 ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
#string fgbioMod
#string samtoolsMod
#string reads3FqGzOriginal
#string bwaSam
#string onekgGenomeFasta
#string addOrReplaceReadGroupsBam
#string annotateBamWithUmisDir
#string annotateBamWithUmisBam
#string annotateBamWithUmisBai

alloutputsexist \
 ${annotateBamWithUmisBam} ${annotateBamWithUmisBai} 
echo "## "$(date)" ##  $0 Started "

getFile ${addOrReplaceReadGroupsBam} 

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${annotateBamWithUmisDir}

echo "## "$(date)" Start $0"

#add umis if present
if [ ${#reads3FqGzOriginal} -eq 0 ]; then
	echo "No umis here"
	exit 1

else
	ml ${fgbioMod}
	#this piece of code reads the umis in memory so more mem as the reads3 file gets bigger
	java -Xmx16g  -Djava.io.tmpdir="${annotateBamWithUmisDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTFGBIO/lib/fgbio-1.3.0.jar AnnotateBamWithUmis \
	 --input "${addOrReplaceReadGroupsBam}" \
	 --fastq ${reads3FqGzOriginal} \
	 --output "${annotateBamWithUmisBam}"
	 

fi

putFile ${annotateBamWithUmisBam}
putFile ${annotateBamWithUmisBai}

echo "## "$(date)" ##  $0 Done "
