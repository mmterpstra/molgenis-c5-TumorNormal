#MOLGENIS nodes=1 ppn=3 mem=16gb walltime=10:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string hisat2Mod
#string picardMod
#string samtoolsMod
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string hisat2AlignmentDir
#string hisat2Sam
#string nTreads
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${hisat2Sam}

#getFile functions

getFile ${onekgGenomeFasta}

#Load modules
${stage} ${hisat2Mod}
${stage} ${picardMod}
${stage} ${samtoolsMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${hisat2AlignmentDir}

#hisat2 -x /apps/data/ftp.broadinstitute.org/bundle/2.8/b37/hisat2/2.0.3-beta-goolf-1.7.20/human_g1k_v37_decoy {-1 <m1> -2 <m2> | -U <r>} [-S <sam>]

if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	getFile ${reads1FqGz}
	readspec=" -U ${reads1FqGz} "
else
	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
	readspec=" -1 ${reads1FqGz} -2 ${reads2FqGz} "
fi

echo "## "$(date)" ##  $0 Align with hisat with readspec='$readspec'"

hisat2 -x ${onekgGenomeFastaIdxBase} $readspec -S /dev/stdout --threads 1 | \
 java -Xmx4g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar CleanSam I=/dev/stdin O=/dev/stdout | \
 samtools view -h - > ${hisat2Sam}

putFile ${hisat2Sam} 

echo "## "$(date)" ##  $0 Done "
