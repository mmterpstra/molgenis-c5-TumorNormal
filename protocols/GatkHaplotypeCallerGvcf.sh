#MOLGENIS walltime=23:59:00 mem=12gb ppn=1

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string gatkMod
#string dbsnpVcf
#string dbsnpVcfIdx
#string onekgGenomeFasta
#string indelRealignmentBam
#string indelRealignmentBai
#string targetsList
#string slopTargetsList

#string haplotyperDir
#string haplotyperGvcf
#string haplotyperGvcfIdx


alloutputsexist \
"${haplotyperGvcf}" \
"${haplotyperGvcfIdx}"

echo "## "$(date)" ##  $0 Started "

for file in "${indelRealignmentBam[@]}" "${indelRealignmentBai[@]}" "${dbsnpVcf}" "${dbsnpVcfIdx}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${checkStage}

#sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n' "${indelRealignmentBam[@]}" | sort -u ))

inputs=$(printf ' -I %s ' $(printf '%s\n' ${bams[@]}))

mkdir -p ${haplotyperDir}

#if has targets use targets list
if [ ${#targetsList} -ne 0 ]; then

	getFile ${slopTargetsList}

	InterValOperand=" -L ${slopTargetsList} "

fi

java -Xmx12g -Djava.io.tmpdir=${haplotyperDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T HaplotypeCaller \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf}\
 $inputs \
 -o ${haplotyperGvcf} \
 --emitRefConfidence GVCF \
 --variant_index_type LINEAR \
 --variant_index_parameter 128000 \
 $InterValOperand

#dem original
# -recoverDanglingHeads \
# -dontUseSoftClippedBases \
# -stand_call_conf 10.0 \
# -stand_emit_conf 20.0 \

putFile ${haplotyperGvcf}
putFile ${haplotyperGvcfIdx}

echo "## "$(date)" ##  $0 Done "
