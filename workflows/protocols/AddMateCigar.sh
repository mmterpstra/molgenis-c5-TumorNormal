#MOLGENIS walltime=23:59:00 mem=12gb nodes=1 ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
#string sampleName
#string sequencer
#string seqType
#string sequencerId
#string flowcellId
#string run
#string lane
#string barcode
#string samplePrep
#string internalId
#string bwaSam
#string mateCigarDir
#string mateCigarBam
#string mateCigarBai


alloutputsexist \
 ${mateCigarBam} \
 ${mateCigarBai}

echo "## "$(date)" ##  $0 Started "

getFile ${bwaSam}

${stage} ${picardMod}
${checkStage}

set -x
set -e

mkdir -p ${mateCigarDir}

echo "## "$(date)" Start $0"


java -Xmx4g -XX:ParallelGCThreads=2 -jar \
 $EBROOTPICARD/picard.jar CleanSam \
 I=${bwaSam} O=/dev/stdout | \
java -Xmx4g -XX:ParallelGCThreads=2 -jar \
 $EBROOTPICARD/picard.jar SortSam \
 SORT_ORDER=queryname I=/dev/stdin O=/dev/stdout | \
java -Xmx4g -XX:ParallelGCThreads=2 -jar \
 $EBROOTPICARD/picard.jar FixMateInformation \
 ADD_MATE_CIGAR=true \
 SORT_ORDER=coordinate \
 I=/dev/stdin O=/dev/stdout | \
 samtools view -h -b - > ${mateCigarBam}

samtools index ${mateCigarBam} ${mateCigarBai}



putFile ${mateCigarBam}
putFile ${mateCigarBai}


echo "## "$(date)" ##  $0 Done "
