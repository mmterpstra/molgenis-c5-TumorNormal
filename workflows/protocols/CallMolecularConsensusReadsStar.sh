#MOLGENIS nodes=1 ppn=4 mem=14gb walltime=36:00:00

#string project



#Parameter mapping

#string stage
#string checkStage
#string fgbioMod
#string picardMod
#string starMod
#string samtoolsMod

#string mergeBamFilesBam
#string nTreads
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase

#string consensusBam
#string consensusBai
#string consensusReads1FqGz
#string consensusReads2FqGz
#string consensusDir
echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${consensusBam}
 
#getFile functions
getFile ${mergeBamFilesBam}
getFile ${onekgGenomeFasta}

#Load modules
${stage} ${fgbioMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${consensusDir}

#groupreads
java -Xmx1g  -Djava.io.tmpdir="${consensusDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap \
 -jar $EBROOTFGBIO/fgbio.jar GroupReadsByUmi \
	 --input="${mergeBamFilesBam}" \
	 --strategy=adjacency \
	 --edits=1 \
	 --min-map-q=20 \
	 --output="${consensusBam}.grouped.bam"

#call consensus
java -Xmx5g  -Djava.io.tmpdir="${consensusDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap \
 -jar $EBROOTFGBIO/fgbio.jar CallMolecularConsensusReads \
	 --input="${consensusBam}.grouped.bam" \
	 --error-rate-post-umi=30 \
	 --min-reads=1 \
	 --output="${consensusBam}.called.bam"

#filterconsensus
java -Xmx1g  -Djava.io.tmpdir="${consensusDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap \
 -jar $EBROOTFGBIO/fgbio.jar FilterConsensusReads \
	 --input="${consensusBam}.called.bam" \
	 --ref="${onekgGenomeFasta}" \
	 --reverse-per-base-tags=true \
	 --min-reads=3 \
	 -E 0.05 \
	 -N 40 \
	 -e 0.1 \
	 -n 0.1 \
	 --output="${consensusBam}.filter.bam" 
#fixups

ml ${samtoolsMod}
#new header cause fgbio omits sequence names in header
(	samtools view -H "${consensusBam}.filter.bam" | grep '^@HD'
	samtools view -H "${mergeBamFilesBam}" | grep '^@SQ' 
	samtools view -H "${consensusBam}.filter.bam" | grep  -v '^@HD' | grep -v '^@SQ'
)> "${consensusBam}.header.sam"



ml ${picardMod}

#
java -Xmx1g  -Djava.io.tmpdir="${consensusDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar ReplaceSamHeader \
 INPUT=${consensusBam}.filter.bam \
 HEADER="${consensusBam}.header.sam" \
 OUTPUT=/dev/stdout | \
java -Xmx6g  -Djava.io.tmpdir="${consensusDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar SortSam \
 INPUT=/dev/stdin \
 SORT_ORDER=queryname \
 OUTPUT="${consensusBam}"


java  -Djava.io.tmpdir="${consensusDir}" -Xmx1g  -XX:+AggressiveOpts -XX:+AggressiveHeap -jar $EBROOTPICARD/picard.jar SamToFastq \
 INPUT="${consensusBam}" \
 FASTQ=${consensusReads1FqGz} \
 SECOND_END_FASTQ=${consensusReads2FqGz}

putFile ${consensusReads1FqGz}
putFile ${consensusReads2FqGz}
putFile ${consensusBam}
echo "## "$(date)" ##  $0 Done "



