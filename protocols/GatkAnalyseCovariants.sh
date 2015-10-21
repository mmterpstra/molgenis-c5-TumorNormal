#MOLGENIS nodes=1 ppn=8 mem=4gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string RMod
#string gatkMod
#string onekgGenomeFasta

#string goldStandardVcf
#string goldStandardVcfIdx
#string oneKgPhase1IndelsVcf
#string oneKgPhase1IndelsVcfIdx

#string dbsnpVcf
#string dbsnpVcfIdx

#string bqsrDir
#string bqsrBam
#string bqsrBai

#string analyseCovarsDir
#string bqsrBeforeGrp
#string bqsrAfterGrp
#string analyseCovariatesPdf

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${bqsrAfterGrp} \
 ${analyseCovariatesPdf} 

getFile ${onekgGenomeFasta}
getFile ${oneKgPhase1IndelsVcf}
getFile ${oneKgPhase1IndelsVcfIdx}
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

java -Xmx4g -Djava.io.tmpdir=${bqsrDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T BaseRecalibrator\
 -R ${onekgGenomeFasta} \
 -I ${bqsrBam} \
 -o ${bqsrAfterGrp} \
 -knownSites ${dbsnpVcf} \
 -knownSites ${goldStandardVcf}\
 -knownSites ${oneKgPhase1IndelsVcf}\
 -nct 8

java -Xmx4g -Djava.io.tmpdir=${bqsrDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T AnalyzeCovariates \
 -R ${onekgGenomeFasta} \
 -ignoreLMT \
 -before ${bqsrBeforeGrp} \
 -after ${bqsrAfterGrp} \
 -plots ${analyseCovariatesPdf} \

putFile ${bqsrAfterGrp}
putFile ${analyseCovariatesPdf}

echo "## "$(date)" ##  $0 Done "
