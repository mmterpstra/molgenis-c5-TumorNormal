#MOLGENIS nodes=1 ppn=8 mem=7gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string gatkOpt
#string onekgGenomeFasta
#string goldStandardVcf
#string goldStandardVcfIdx

#string oneKgPhase1IndelsVcf
#string oneKgPhase1IndelsVcfIdx

#string dbsnpVcf
#string dbsnpVcfIdx

#string indelRealignmentBam
#string indelRealignmentBai
#string bqsrDir
#string bqsrBam
#string bqsrBai
#string bqsrBeforeGrp

#pseudo from gatk forum (link: http://gatkforums.broadinstitute.org/discussion/3891/best-practices-for-variant-calling-on-rnaseq):
#java -jar GenomeAnalysisTK.jar -T SplitNCigarReads -R ref.fasta -I dedupped.bam -o split.bam -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${bqsrBam} \
 ${bqsrBai}

getFile ${onekgGenomeFasta}
getFile ${oneKgPhase1IndelsVcf}
getFile ${oneKgPhase1IndelsVcfIdx}
getFile ${dbsnpVcf}
getFile ${dbsnpVcfIdx}
getFile ${goldStandardVcf} 
getFile ${goldStandardVcfIdx}
getFile ${indelRealignmentBam}
getFile ${indelRealignmentBai}

${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${bqsrDir}

#do bqsr for covariable determination then do print reads for valid bsqrbams
#check the bqsr part and add known variants

java -Xmx6g -Djava.io.tmpdir=${bqsrDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T BaseRecalibrator\
 -R ${onekgGenomeFasta} \
 -I ${indelRealignmentBam} \
 -o ${bqsrBeforeGrp} \
 -knownSites ${dbsnpVcf} \
 -knownSites ${goldStandardVcf}\
 -knownSites ${oneKgPhase1IndelsVcf}\
 -nct 8

java -Xmx4g -Djava.io.tmpdir=${bqsrDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T PrintReads \
 -R ${onekgGenomeFasta} \
 -I ${indelRealignmentBam} \
 -o ${bqsrBam} \
 -BQSR ${bqsrBeforeGrp} \
 -nct 8 \
 ${gatkOpt}

putFile ${bqsrBam}
putFile ${bqsrBai}
putFile ${bqsrBeforeGrp}

echo "## "$(date)" ##  $0 Done "
