#MOLGENIS walltime=5:59:00 mem=12gb ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir
#string dbsnpVcf
#string dbsnpVcfIdx

#string gatkMod
#string gHaplotyperDir
#string onekgGenomeFasta

#string combinedScatGvcf
#string combinedScatGvcfIdx

#string genotypedScatVcf
#string genotypedScatVcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${genotypedScatVcf}" \
"${genotypedScatVcfIdx}"

for file in "${combinedScatGvcf[@]}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${checkStage}

set -x
set -e


# sort unique and print like ' --variant file1.vcf --variant file2.vcf '
gvcfs=($(printf '%s\n' "${combinedScatGvcf[@]}" | sort -u ))

inputs=$(printf ' --variant %s ' $(printf '%s\n' ${gvcfs[@]}))

mkdir -p ${gHaplotyperDir}

#pseudo: java -jar GenomeAnalysisTK.jar -T HaplotypeCaller -R ref.fasta -I input.bam -recoverDanglingHeads -dontUseSoftClippedBases -stand_call_conf 20.0 -stand_emit_conf 20.0 -o output.vcf from http://gatkforums.broadinstitute.org/discussion/3891/calling-variants-in-rnaseq

java -Xmx12g -Djava.io.tmpdir=${gHaplotyperDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T GenotypeGVCFs \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf} \
 -o ${genotypedScatVcf} \
 $inputs \
 -stand_call_conf 10.0 \
 -nt 4 \
 -newQual


putFile ${genotypedScatVcf}
putFile ${genotypedScatVcfIdx}

echo "## "$(date)" ##  $0 Done "I
