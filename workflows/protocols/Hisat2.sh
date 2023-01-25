#MOLGENIS nodes=1 ppn=7 mem=24gb walltime=20:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string hisat2Mod
#string picardMod
#string samtoolsMod
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string hisat2SpliceKnownTxt
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

getFile ${onekgGenomeFasta} ${hisat2SpliceKnownTxt}

#Load modules
${stage} ${hisat2Mod}
${stage} ${picardMod}
${stage} ${samtoolsMod}

#check modules
${checkStage}


set -x
set -e
set -o pipefail

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
#note the cleansam diffcult stuff is for read alignments going outside the reference seqs (still it occasionally happens).

#this ugly alright but the idea is that the last step just idles until the first three complete due to the nature of sorting.
hisat2 \
 -x "${onekgGenomeFastaIdxBase}" \
 $readspec \
 --known-splicesite-infile "${hisat2SpliceKnownTxt}" \
 --score-min L,0,-0.6 \
 --sp 1,1.5 -D 20 -R 3 -S \
 /dev/stdout --threads 4 | \
java \
 -Xmx4g \
 -XX:ParallelGCThreads=2 \
 -Djava.io.tmpdir="${hisat2AlignmentDir}" \
 -jar $EBROOTPICARD/picard.jar CleanSam \
 I=/dev/stdin O=/dev/stdout | \
java \
 -Xmx4g \
 -XX:ParallelGCThreads=2 \
 -Djava.io.tmpdir="${hisat2AlignmentDir}" \
 -jar $EBROOTPICARD/picard.jar SortSam \
 SORT_ORDER=queryname I=/dev/stdin O=/dev/stdout | \
java \
 -Xmx4g \
 -XX:ParallelGCThreads=2 \
 -Djava.io.tmpdir="${hisat2AlignmentDir}" \
 -jar $EBROOTPICARD/picard.jar FixMateInformation \
 ADD_MATE_CIGAR=true \
 I=/dev/stdin O=/dev/stdout | \
 samtools view -h - > "${hisat2Sam}"

putFile ${hisat2Sam} 

echo "## "$(date)" ##  $0 Done "
