#MOLGENIS nodes=1 ppn=1 mem=10gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string samtoolsMod
#string onekgGenomeFasta
#string targetsList
#string cosmicVcf
#string dbsnpVcf
#string scatterList


#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai
#string controlSampleBam
#string controlSampleBai

#string mutect2ScatVcf
#string mutect2ScatVcfIdx
#string mutect2Dir


#pseudo from gatk forum (link: http://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_sting_gatk_walkers_indels_IndelRealigner):
#java -Xmx4g -jar GenomeAnalysisTK.jar -T IndelRealigner -R ref.fa -I input.bam -targetIntervals intervalListFromRTC.intervals -o realignedBam.bam [-known /path/to/indels.vcf] -U ALLOW_N_CIGAR_READS --allow_potentially_misencoded_quality_scores

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${mutect2ScatVcf} \
 ${mutect2ScatVcfIdx}

${stage} ${samtoolsMod}
${stage} ${gatkMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${indelRealignmentBam}
getFile ${indelRealignmentBai}
getFile ${controlSampleBam}
getFile ${controlSampleBai}
getFile ${cosmicVcf}
getFile ${dbsnpVcf}

set -x
set -e

mkdir -p ${mutect2Dir}

#if has targets use targets list
if [ ${#targetsList} -ne 0 ]; then

	getFile ${scatterList}

	if [ ! -e ${scatterList} ]; then

		line="skipping this haplotypecaller because not -e ${scatterList}"
		echo $line
		echo $line 1>&2

		if [ -e $ENVIRONMENT_DIR/${taskId}.sh ]; then 
			touch $ENVIRONMENT_DIR/${taskId}.sh.finished
			touch $ENVIRONMENT_DIR/${taskId}.env
		fi
		exit 0;
	fi


	InterValOperand=" -L ${scatterList} "

fi


Normalspec=""

if [ ${indelRealignmentBam} !=  ${controlSampleBam} ]; then
	normalspec="-I:normal ${controlSampleBam} "
fi

java -Xmx8g -Djava.io.tmpdir=${mutect2Dir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T MuTect2 \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf} \
 --cosmic ${cosmicVcf} \
 -I:tumor ${indelRealignmentBam} \
 $Normalspec \
 $InterValOperand \
 -o ${mutect2ScatVcf}


#java -Xmx8g -Djava.io.tmpdir=${haplotyperDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
# -T HaplotypeCaller \
# -R ${onekgGenomeFasta} \
# --dbsnp ${dbsnpVcf}\
# $inputs \
# -stand_call_conf 10.0 \
# -o ${haplotyperScatVcf} \
# $InterValOperand \
# ${gatkOpt}


#java -jar GenomeAnalysisTK.jar \
#     -T MuTect2 \
#     -R reference.fasta \
#     -I:tumor tumor.bam \
#     -I:normal normal.bam \
#     [--dbsnp dbSNP.vcf] \
#     [--cosmic COSMIC.vcf] \
#     [-L targets.interval_list] \
#     -o output.vcf
# -I:eval ${indelRealignmentBam} \
# -I:genotype ${controlSampleBam} \
# --popfile ${popStratifiedVcf} \
# -L ${popStratifiedVcf} \
# -L ${targetsList} \
# -isr INTERSECTION \
# -o ${contEstLog}

#cp -v ${indelRealignmentBai} ${indelRealignmentBam}.bai

putFile ${mutect2ScatVcf}


echo "## "$(date)" ##  $0 Done "
