#MOLGENIS walltime=23:59:00 mem=4gb ppn=1
################################^advised 45 gb for 300 files so 30 for 200 files?
#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir
#string onekgGenomeFasta
#string gatkMod
#list haplotyperGvcf,haplotyperGvcfIdx

#string haplotyperDir
#string mergeGvcf
#string mergeGvcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${mergeGvcf}" \
"${mergeGvcfIdx}"

for file in "${haplotyperGvcf[@]}" "${haplotyperGvcfIdx[@]}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${checkStage}

set -x
set -e

#sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
gvcfs=($(printf '%s\n' "${haplotyperGvcf[@]}" | sort -u ))

inputs=$(printf ' --variant %s ' $(printf '%s\n' ${gvcfs[@]}))

mkdir -p ${haplotyperDir}

java -Xmx4g -Djava.io.tmpdir=${haplotyperDir} -jar $GATK_HOME/GenomeAnalysisTK.jar \
 -T CombineGVCFs \
 -R ${onekgGenomeFasta} \
 -o ${mergeGvcf} \
 $inputs 


putFile ${mergeGvcf}
putFile ${mergeGvcf}

echo "## "$(date)" ##  $0 Done "
