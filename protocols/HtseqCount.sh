#MOLGENIS walltime=23:59:00 mem=8gb nodes=1 ppn=4
#string project

#string stage
#string checkStage
#string projectDir

#string picardMod
#string samtoolsMod
#string htseqMod

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

java -Xmx6g -Djava.io.tmpdir=${htseqDir} -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar SortSam \
 INPUT=${markDuplicatesBam} \
 OUTPUT=/dev/stdout \
 MAX_RECORDS_IN_RAM=4000000 \
 SORT_ORDER=queryname | \
samtools view -h - | \
python $EBROOTHTSEQ/scripts/htseq-count -m union -s no -t exon -i gene_id - ${ensemblAnnotationGtf} > ${htseqTsv}


putFile ${htseqTsv}

echo "## "$(date)" ##  $0 Done "
