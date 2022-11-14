#MOLGENIS nodes=1 ppn=4 mem=8gb walltime=23:59:00

#string project

#string mergeBamFilesBam
#string onekgGenomeFastaIdxBase


#Parameter mapping

#string stage
#string checkStage
#string fgbioMod
#string picardMod
#string samtoolsMod

#string onekgGenomeFasta

#string sampleName
#string consensusBam
#string consensusBai
#string consensusDir
#string combineScatVcf

#string annotateConsensusDir
#string annotateConsensusBase
#string annotateConsensusBaseDir

echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${annotateConsensusBase}.txt
 
#getFile functions
getFile ${mergeBamFilesBam}
getFile ${onekgGenomeFasta}

#Load modules
${stage} ${fgbioMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${annotateConsensusDir}
mkdir -p ${annotateConsensusBaseDir}



#sort & index ${consensusBam}.grouped.bam > $(dirname ${annotateConsensusDir})/${consensusBam}.sorted.grouped.bam
(
	ml ${samtoolsMod}
	getFile ${consensusBam}.grouped.bam
	samtools sort ${consensusBam}.grouped.bam \
		> ${annotateConsensusBaseDir}/$(basename ${consensusBam}).sorted.grouped.bam
	samtools index \
		${annotateConsensusBaseDir}/$(basename ${consensusBam}).sorted.grouped.bam
)
java -Xmx6g  -Djava.io.tmpdir="${consensusDir}" -XX:+AggressiveOpts -XX:+AggressiveHeap \
 -jar $EBROOTFGBIO/fgbio.jar \
 ReviewConsensusVariants \
 -r ${onekgGenomeFasta} \
 -c "${consensusBam}" \
 -s "${sampleName}" \
 -g "${annotateConsensusBaseDir}""/""$(basename "${consensusBam}")".sorted.grouped.bam \
 -i ${combineScatVcf} \
 -m 0.08 \
 -o ${annotateConsensusBase}


#ml pipeline-util
#
#AddFragCountsToVariants.pl -v bla.vcf -c ${annotateConsensusBase}


putFile ${annotateConsensusBase}.txt
putFile ${annotateConsensusBaseDir}/$(basename ${consensusBam}).sorted.grouped.bam

echo "## "$(date)" ##  $0 Done "



