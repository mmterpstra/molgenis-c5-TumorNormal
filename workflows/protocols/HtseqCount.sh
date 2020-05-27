#MOLGENIS walltime=23:59:00 mem=10gb nodes=1 ppn=4
#string project

#string stage
#string checkStage
#string projectDir

#string picardMod
#string samtoolsMod
#string htseqMod
#string htseqStranded
#string ensemblAnnotationGtf
#string markDuplicatesBam
#string markDuplicatesBai

#string htseqDir
#string htseqTsv

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${htseqTsv}

getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}
getFile ${ensemblAnnotationGtf}

${stage} ${picardMod}
${stage} ${samtoolsMod}
${stage} ${htseqMod}
${checkStage}

set -x
set -e

mkdir -p ${htseqDir}



if [ -e $EBROOTHTSEQ/scripts ]; then
	htseqBinDir="scripts"
elif [ -e  $EBROOTHTSEQ/bin ]; then
        htseqBinDir="bin"
else
	echo "## "$(date)" ## No Htseq bindir found!.Plz fix this script."
	exit -1
fi



java -Xmx8g -Djava.io.tmpdir=${htseqDir} -XX:ParallelGCThreads=8 -jar $EBROOTPICARD/picard.jar SortSam \
 INPUT=${markDuplicatesBam} \
 OUTPUT=/dev/stdout \
 MAX_RECORDS_IN_RAM=4000000 \
 SORT_ORDER=queryname \
 TMP_DIR=${htseqDir} | \
samtools view -h -F 1024 - | \
python $EBROOTHTSEQ/$htseqBinDir/htseq-count -m union ${htseqStranded} -t exon -i gene_id - ${ensemblAnnotationGtf} > ${htseqTsv}


putFile ${htseqTsv}

echo "## "$(date)" ##  $0 Done "
