#MOLGENIS nodes=1 ppn=8 mem=7gb walltime=47:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string gatkOpt
#string onekgGenomeFasta
#string ensemblAnnotationGtf
#string mergeBamFilesBam
#string mergeBamFilesBai
#string abraDir
#string abraBam
#string abraBai

#pseudo from gatk forum (link: http://gatkforums.broadinstitute.org/discussion/3891/best-practices-for-variant-calling-on-rnaseq):
#java -jar GenomeAnalysisTK.jar -T SplitNCigarReads -R ref.fasta -I dedupped.bam -o split.bam -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${abraBam} \
 ${abraBai}

getFile ${onekgGenomeFasta}
getFile ${mergeBamFilesBam}
getFile ${mergeBamFilesBai}

${stage} ${abraMod}
${checkStage}

set -x
set -e

mkdir -p ${abraDir}

#abra2 realgnment on targets rna seq...
#java -Xmx16G -jar abra2.jar \
# --in star.bam \
# --out star.abra.bam \
# --ref hg38.fa \
# --junctions bam \
# --threads 8 \
# --gtf gencode.v26.annotation.gtf \
# --dist 500000 \
# --sua --tmpdir /your/tmpdir > abra2.log 2>&1

#it breaks on number formatting using the not US locale https://github.com/mozack/abra2/issues/25
export LC_ALL=en_US.UTF-8

java -Xmx16G -jar abra2.jar \
 --in ${mergeBamFilesBam} \
 --out ${abraBam} \
 --ref ${onekgGenomeFasta} \
 --junctions bam \
 --threads 8 \
 --gtf ${ensemblAnnotationGtf} \
 --dist 500000 \
 --sua --tmpdir ${abraDir}

putFile ${abraBam}
putFile ${abraBai}

echo "## "$(date)" ##  $0 Done "
