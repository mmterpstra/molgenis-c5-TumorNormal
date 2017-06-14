#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string pipelineUtilMod
#string gatkMod
#string onekgGenomeFasta
#string haplotyperVcf
#string freebayesVcf

#string variantCombineDir
#string combineVcf
#string combineVcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${combineVcf}" \
"${combineVcfIdx}" 

for file in "${onekgGenomeFasta}" "${freebayesVcf}" "${haplotyperVcf}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${pipelineUtilMod}
${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${variantCombineDir}

#
java -Xmx4g -Djava.io.tmpdir=/scratch/umcg-mterpstra/projects/1703_Ferronika_Nugen_136_135_test//combinevariants/ \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T VariantsToAllelicPrimitives \
 -R /data/umcg-mterpstra/apps/data//ftp.broadinstitute.org/bundle/2.8/b37//human_g1k_v37_decoy.fasta \
 -V  ${freebayesVcf} \
 -o ${freebayesVcf}.allelicprimitives.vcf

perl -i.bak -wpe 'if(not((m/^#/) ||  (m/TYPE=complex;/||m/TYPE=snp;/||m/TYPE=del;/||m/TYPE=ins;/||m/TYPE=mnp;/))){$_="";}' \
 ${freebayesVcf}.allelicprimitives.vcf

rm ${freebayesVcf}.allelicprimitives.vcf.idx

#merge gatk/freebayes
java -Xmx4g -Djava.io.tmpdir=${variantCombineDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T CombineVariants \
 -R ${onekgGenomeFasta} \
 --variant:GATK ${haplotyperVcf} \
 --variant:freebayes  ${freebayesVcf}.allelicprimitives.vcf \
 -o ${combineVcf}.tmp.vcf \
 -genotypeMergeOptions PRIORITIZE \
 -priority GATK,freebayes \
 --filteredrecordsmergetype KEEP_UNCONDITIONAL

perl $EBROOTPIPELINEMINUTIL/bin/filterCombinedVariantsForGatk.pl \
 ${combineVcf}.tmp.vcf > ${combineVcf}
putFile ${combineVcf}
putFile ${combineVcfIdx}

echo "## "$(date)" ##  $0 Done "
