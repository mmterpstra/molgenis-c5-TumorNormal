#MOLGENIS nodes=1 ppn=1 mem=8gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string fastqcMod
#string samtoolsMod
#string onekgGenomeFasta
#string gatkOpt

#string markDuplicatesBam
#string markDuplicatesBai

#string samQcDir
#string samQcFlagStatLog
#string samQcStatsLog
#string samQcIdxStatsLog
#string samQcDupStatsLog


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${samQcIdxStatsLog} \
 ${samQcFlagStatLog} \
 ${samQcStatsLog} \
 ${samQcDupStatsLog}

${stage} ${samtoolsMod}
${stage} ${fastqcMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}

set -x
set -e

mkdir -p ${samQcDir}

#for old samtools:
#cp ${markDuplicatesBai} ${markDuplicatesBam}.bai

samtools idxstats ${markDuplicatesBam} > ${samQcIdxStatsLog}
samtools flagstat ${markDuplicatesBam} > ${samQcFlagStatLog}
samtools stats -d -r ${onekgGenomeFasta} ${markDuplicatesBam} > ${samQcStatsLog}
samtools stats -r ${onekgGenomeFasta} ${markDuplicatesBam} > ${samQcDupStatsLog}
fastqc --noextract --outdir ${samQcDir} ${markDuplicatesBam}



putFile ${samQcIdxStatsLog}
putFile ${samQcFlagStatLog}
putFile ${samQcStatsLog}
putFile ${samQcDupStatsLog}


echo "## "$(date)" ##  $0 Done "
