#MOLGENIS nodes=1 ppn=1 mem=10gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string samtoolsMod
#string pipelineUtilMod
#string onekgGenomeFasta
#string targetsList
#string cosmicVcf
#string dbsnpVcf
#string scatterList
#string mutect2PonProjectScatVcf
#string mutect2PonProjectScatVcfIdx

#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai
#string controlSampleBam
#string controlSampleBai
#string mutect2ScatVcf
#string mutect2ScatVcfIdx
#string mutect2Dir


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${mutect2ScatVcf} \
 ${mutect2ScatVcfIdx}

${stage} ${samtoolsMod} ${gatkMod} ${pipelineUtilMod}
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

#normalspec run only when they aren't the same bam/sample
if [ ${indelRealignmentBam} !=  ${controlSampleBam} ]; then
	#run with controlsample
        echo "## "$(date)" ##  $0 Running with controlsample '${controlSampleBam}'."

	Normalspec="-I:normal ${controlSampleBam} "
fi

#this should override the normalspec and the data should be ran only when using Panel Of Normals generation
if [ ! -e ${mutect2PonProjectScatVcf} ]; then
	
	echo "## "$(date)" ##  $0 Running in panel of normals mode."

	Normalspec='--artifact_detection_mode '
	
fi


java -Xmx8g -Djava.io.tmpdir=${mutect2Dir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T MuTect2 \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf} \
 --cosmic ${cosmicVcf} \
 -I:tumor ${indelRealignmentBam} \
 $Normalspec \
 $InterValOperand \
 -o ${mutect2ScatVcf}.tmp.vcf

#cleans name of any not [a-zA-Z0-9_]. It is up to the human interpreter to interpret these names, if needed.

#sampleNameClean=$(echo "${sampleName}" | perl -wpe 'chomp;$_=uc;s/\W/_/g;')

#this should be better than callerise is this case
perl $EBROOTPIPELINEMINUTIL/bin/MutectAnnotationsToSampleFormat.pl TLOD,NLOD,MIN_ED,MAX_ED,ECNT,HCNT ${mutect2ScatVcf}.tmp.vcf  > ${mutect2ScatVcf}

NORMAL="$(perl -wne 'if(s/.*NORMAL,SampleName=(.*?),.*/$1/){print};' ${mutect2ScatVcf})"
TUMOR="$(perl -wne 'if(s/.*TUMOR,SampleName=(.*?),.*/$1/){print};' ${mutect2ScatVcf})"
perl -i.tumornormal.bak -wpe 's/\tNORMAL/\t'"$NORMAL"'/;s/\tTUMOR/\t'"$TUMOR"'/;' ${mutect2ScatVcf}


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
