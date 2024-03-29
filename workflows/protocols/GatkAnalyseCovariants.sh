#MOLGENIS nodes=1 ppn=8 mem=6gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string RMod
#string gatkMod
#string gatkOpt
#string onekgGenomeFasta

#string goldStandardVcf
#string goldStandardVcfIdx

#string dbsnpVcf
#string dbsnpVcfIdx

#string bqsrDir
#string bqsrBam
#string bqsrBai

#string analyseCovarsDir
#string bqsrBeforeGrp
#string bqsrAfterGrp
#string analyseCovariatesCsv

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${bqsrAfterGrp} \
 ${analyseCovariatesCsv} 

getFile ${onekgGenomeFasta}
getFile ${dbsnpVcf}
getFile ${dbsnpVcfIdx}
getFile ${goldStandardVcf} 
getFile ${goldStandardVcfIdx}
getFile ${bqsrBam}
getFile ${bqsrBai}

${stage} ${RMod}
${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${analyseCovarsDir}

#do bqsr for covariable determination then do print reads for valid bsqrbams
#check the bqsr part and add known variants

java -Xmx6g -Djava.io.tmpdir=${bqsrDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T BaseRecalibrator\
 -R ${onekgGenomeFasta} \
 -I ${bqsrBam} \
 -o ${bqsrAfterGrp} \
 -knownSites ${dbsnpVcf} \
 -knownSites ${goldStandardVcf}\
 -nct 8

java -Xmx6g -Djava.io.tmpdir=${bqsrDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T AnalyzeCovariates \
 -R ${onekgGenomeFasta} \
 -ignoreLMT \
 -before ${bqsrBeforeGrp} \
 -after ${bqsrAfterGrp} \
 -csv ${analyseCovariatesCsv} \
 ${gatkOpt}

putFile ${bqsrAfterGrp}
putFile ${analyseCovariatesCsv}

echo "## "$(date)" ##  $0 Done "
