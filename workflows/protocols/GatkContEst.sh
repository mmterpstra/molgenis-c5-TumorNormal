#MOLGENIS nodes=1 ppn=1 mem=10gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string samtoolsMod
#string onekgGenomeFasta
#string targetsList

#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai
#string controlSampleBam
#string controlSampleBai
#string popStratifiedVcf
#string popStratifiedVcfIdx
#string contEstLog
#string contEstDir

#pseudo from gatk forum (link: http://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_sting_gatk_walkers_indels_IndelRealigner):
#java -Xmx4g -jar GenomeAnalysisTK.jar -T IndelRealigner -R ref.fa -I input.bam -targetIntervals intervalListFromRTC.intervals -o realignedBam.bam [-known /path/to/indels.vcf] -U ALLOW_N_CIGAR_READS --allow_potentially_misencoded_quality_scores

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${contEstLog}

${stage} ${samtoolsMod}
${stage} ${gatkMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${indelRealignmentBam}
getFile ${indelRealignmentBai}
getFile ${controlSampleBam}
getFile ${controlSampleBai}
getFile ${popStratifiedVcf}
#getFile ${popStratifiedVcfIdx}

set -x
set -e

if [ ! -e ${indelRealignmentDir} ]; then
	mkdir -p ${indelRealignmentDir}
fi

mkdir -p "${contEstDir}"

if [ ! "${indelRealignmentBam}" == "${controlSampleBam}" ] ;then

	java -Xmx8g -Djava.io.tmpdir=${contEstDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
	 -T ContEst \
	 -R ${onekgGenomeFasta} \
	 -I:eval ${indelRealignmentBam} \
	 -I:genotype ${controlSampleBam} \
	 --popfile ${popStratifiedVcf} \
	 -L ${popStratifiedVcf} \
	 -L ${targetsList} \
	 -isr INTERSECTION \
	 -o ${contEstLog}

else
	touch ${contEstLog}
fi
#cp -v ${indelRealignmentBai} ${indelRealignmentBam}.bai

putFile ${contEstLog}


echo "## "$(date)" ##  $0 Done "
