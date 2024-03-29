#MOLGENIS walltime=23:59:00 mem=9gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string gatkMod
#string gatkOpt
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
 --dbsnp ${dbsnpVcf} \
 $inputs \
 -stand_call_conf 10.0 \
 -o ${haplotyperScatVcf} \
 -newQual \
 $InterValOperand \
 ${gatkOpt}

#since we are working with batches of 100 --max-alternate-alleles 10 should catch everything
#--max-mnp-distance 2 cause i dont like the output of gatk
#--max-assembly-region-size == 500 cause intorrent?
# --max-alternate-alleles 10 #tooldocs are messy why do the generic commands fail?
# -dontUseSoftClippedBases \

putFile ${haplotyperScatVcf}
putFile ${haplotyperScatVcfIdx}

echo "## "$(date)" ##  $0 Done "
