#MOLGENIS nodes=1 ppn=1 mem=8gb walltime=23:59:00

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string onekgGenomeFasta
#string splitAndTrimBam
#string splitAndTrimBai

#string goldStandardVcf
#string realignmentIntervals
#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai

#pseudo from gatk forum (link: http://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_sting_gatk_walkers_indels_IndelRealigner):
#java -Xmx4g -jar GenomeAnalysisTK.jar -T IndelRealigner -R ref.fa -I input.bam -targetIntervals intervalListFromRTC.intervals -o realignedBam.bam [-known /path/to/indels.vcf] -U ALLOW_N_CIGAR_READS --allow_potentially_misencoded_quality_scores

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${indelRealignmentBam} \
 ${indelRealignmentBai}

getFile ${onekgGenomeFasta}
getFile ${splitAndTrimBam}
getFile ${splitAndTrimBai}

${stage} ${gatkMod}
${checkStage}

set -x
set -e

if [ ! -e ${indelRealignmentDir} ]; then
	mkdir -p ${indelRealignmentDir}
fi



java -Xmx8g -Djava.io.tmpdir=${indelRealignmentDir} -jar $GATK_HOME/GenomeAnalysisTK.jar \
 -T IndelRealigner \
 -R ${onekgGenomeFasta} \
 -I ${splitAndTrimBam} \
 -o ${indelRealignmentBam} \
 -targetIntervals ${realignmentIntervals} \
 -known ${goldStandardVcf} \
 -U ALLOW_N_CIGAR_READS

putFile ${indelRealignmentBam}
putFile ${indelRealignmentBai}

echo "## "$(date)" ##  $0 Done "
