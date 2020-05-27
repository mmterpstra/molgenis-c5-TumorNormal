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
#string bqsrBam
#string bqsrBai
#string targetsList
#string scatterList
#string gHaplotyperDir
#string haplotyperScatGvcf
#string haplotyperScatGvcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${haplotyperScatGvcf}" \
"${haplotyperScatGvcfIdx}"

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

mkdir -p ${gHaplotyperDir}

java -Xmx12g -Djava.io.tmpdir=${gHaplotyperDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T HaplotypeCaller \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf}\
 $inputs \
 -o ${haplotyperScatGvcf} \
 --emitRefConfidence GVCF \
 -newQual \
 $InterValOperand \
  ${gatkOpt}

#since we are working with batches of 100 --max-alternate-alleles 10 should catch everything
#--max-mnp-distance 2 cause i dont like the output of gatk
#--max-assembly-region-size == 500 cause intorrent?
# --max-alternate-alleles 10 #tooldocs are messy why do the generic commands fail?
# -dontUseSoftClippedBases \

putFile ${haplotyperScatGvcf}
putFile ${haplotyperScatGvcfIdx}

echo "## "$(date)" ##  $0 Done "
