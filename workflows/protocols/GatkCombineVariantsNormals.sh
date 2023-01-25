#MOLGENIS walltime=71:59:00 mem=30gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string pipelineUtilMod
#string gatkMod
#string bcftoolsMod
#string onekgGenomeFasta
#list mutect2Vcf
#list mutect2VcfIdx

#string combinedNormalsDir
#string combinedNormalsVcf
#string combinedNormalsVcfIdx

#string gatkMod
#string gatkOpt
#string dbsnpVcf
#string dbsnpVcfIdx
#string onekgGenomeFasta
#list bqsrBam,bqsrBai
#string freebayesProjectBam
#string freebayesMod

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${combinedNormalsVcf}" \
"${combinedNormalsVcfIdx}" 

for file in "${onekgGenomeFasta}" "${mutect2Vcf[@]}" "${mutect2VcfIdx[@]}" ; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${pipelineUtilMod}
${stage} ${freebayesMod}
${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${variantCombineDir}

#

#merge gatk/freebayes/mutect
java -Xmx4g -Djava.io.tmpdir=${variantCombineDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T CombineVariants \
 -R ${onekgGenomeFasta} \
 --variant:GATK ${combineVcf}.tmp.haplotypernorm.vcf \
 --variant:freebayes  ${combineVcf}.tmp.freebayesnorm.vcf \
 --variant:MuTect2 ${combineVcf}.tmp.mutect2norm.vcf \
 --variant:LoFreq ${combineVcf}.tmp.lofreqnorm.vcf \
 --variant:Lancet ${combineVcf}.tmp.lancetnorm.vcf \
 -o ${combinedNormalsVcf} \
 -genotypeMergeOptions PRIORITIZE \
 -priority GATK,freebayes,MuTect2,LoFreq,Lancet \
 --filteredrecordsmergetype KEEP_UNCONDITIONAL

#rm -v ${combineVcf}.tmp.*.vcf

putFile ${combinedNormalsVcf}
#putFile ${combineVcfIdx}

echo "## "$(date)" ##  $0 Done "
