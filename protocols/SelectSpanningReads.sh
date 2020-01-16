#MOLGENIS walltime=23:59:00 mem=2gb nodes=1 ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string bedtoolsMod
#string samtoolsMod
#string onekgGenomeFasta
#string addOrReplaceReadGroupsDir
#string addOrReplaceReadGroupsBam
#string addOrReplaceReadGroupsBai
#string ampliconsBed

#string spanningBam
#string spanningBai
#string spanningDir


alloutputsexist \
 ${spanningBam} \
 ${spanningBai}

echo "## "$(date)" ##  $0 Started "

getFile ${addOrReplaceReadGroupsBam}
getFile ${addOrReplaceReadGroupsBai}
getFile ${onekgGenomeFasta}
getFile ${ampliconsBed}

${stage} ${bedtoolsMod}
${stage} ${samtoolsMod}
${checkStage}

set -x
set -e
set -o pipefail

mkdir -p ${spanningDir}

echo "## "$(date)" Start $0"

#-F = fraction of overlap with '-b' this should be somewhere between ~0.85% ~0.90%  because with amplicons the last ~10% is just adapter, also some amplicons seem to be a bit off.
#-u = Only report overlap of '-a' once
#-sorted = Use sorted input
#tee for indexing on the fly / error checking

cut -f 1,2 ${onekgGenomeFasta}.fai > ${spanningBam}.genome.file

bedtools intersect \
 -g ${spanningBam}.genome.file \
 -F 0.85 \
 -f 0.85 \
 -u \
 -sorted \
 -a ${addOrReplaceReadGroupsBam} \
 -b ${ampliconsBed} \
 | tee  ${spanningBam} \
 | samtools index /dev/stdin ${spanningBai}

rm ${spanningBam}.genome.file

putFile ${spanningBam}
putFile ${spanningBai}


echo "## "$(date)" ##  $0 Done "
