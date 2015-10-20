#MOLGENIS walltime=23:59:00 mem=8gb ppn=1

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string gatkMod
#string dbsnpVcf
#string dbsnpVcfIdx
#string onekgGenomeFasta
#list bqsrBam,bqsrBai
#string targetsList
#string scatterList
#string haplotyperDir
#string haplotyperScatVcf
#string haplotyperScatVcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${haplotyperScatVcf}" \
"${haplotyperScatVcfIdx}"

for file in "${bqsrBam[@]}" "${bqsrBai[@]}" "${dbsnpVcf}" "${dbsnpVcfIdx}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${checkStage}

set -x
set -e

# sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n' "${bqsrBam[@]}" | sort -u ))

inputs=$(printf ' -I %s ' $(printf '%s\n' ${bams[@]}))

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

mkdir -p ${haplotyperDir}

java -Xmx8g -Djava.io.tmpdir=${haplotyperDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T HaplotypeCaller \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf}\
 $inputs \
 -stand_call_conf 10.0 \
 -stand_emit_conf 20.0 \
 -o ${haplotyperScatVcf} \
 $InterValOperand

# -dontUseSoftClippedBases \

putFile ${haplotyperScatVcf}
putFile ${haplotyperScatVcfIdx}

echo "## "$(date)" ##  $0 Done "
