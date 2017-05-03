#MOLGENIS walltime=23:59:00 mem=2gb nodes=1 ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string bedtoolsMod
#string samtoolsMod
#string addOrReplaceGroupsDir
#string addOrReplaceGroupsBam
#string addOrReplaceGroupsBai
#string ampliconsBed

#string spanningBam
#string	spanningBai
#string spanningDir


alloutputsexist \
 ${spanningBam} \
 ${spanningBai}

echo "## "$(date)" ##  $0 Started "

getFile ${addOrReplaceGroupsBam}
getFile ${addOrReplaceGroupsBai}


${stage} ${bedtoolsMod}
${stage} ${samtoolsMod}
${checkStage}

set -x
set -e

mkdir -p ${spanningDir}

echo "## "$(date)" Start $0"

#-F = fraction of overlap with '-b' this should be somewhere between ~0.90 and 0.99 because with amplicons the last ~10% is just adapter.
#-u = Only report overlap of '-a' once
#-sorted = Use sorted input
#tee for indexing on the fly / error checking

bedtools intersect \
 -F 0.95 \
 -r
 -u \
 -sorted \
 -a ${addOrReplaceGroupsBam} \
 -b ${ampliconsBed} \
 | tee  ${spanningBam} \
 | samtools index - ${spanningBai}

putFile ${spanningBam}
putFile ${spanningBai}


echo "## "$(date)" ##  $0 Done "
