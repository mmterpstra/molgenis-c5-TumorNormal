#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string pipelineUtilMod
#string gatkMod
#string bcftoolsMod
#string onekgGenomeFasta
#string haplotyperVcf
#string freebayesVcf
#string mutect2Vcf

#string variantCombineDir
#string combineVcf
#string combineVcfIdx

#string gatkMod
#string gatkOpt
#string dbsnpVcf
#string dbsnpVcfIdx
#string onekgGenomeFasta
#list bqsrBam,bqsrBai

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${combineVcf}" \
"${combineVcfIdx}" 

for file in "${onekgGenomeFasta}" "${freebayesVcf}" "${haplotyperVcf}" "${mutect2Vcf}"; do
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
java -Xmx4g -Djava.io.tmpdir=${variantCombineDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T VariantsToAllelicPrimitives \
 -R ${onekgGenomeFasta} \
 -V  ${freebayesVcf} \
 -o ${combineVcf}.tmp.allelicprimitives.vcf

#remove complex snps from freebayes: depeciated because larger project will combine adjecent overlapping indels/snps into one and mark them as complex. Missing variants. 
#perl -i.bak -wpe 'if(not((m/^#/) ||  (m/TYPE=complex[;\t]/||m/TYPE=snp[;\t]/||m/TYPE=del[;\t]/||m/TYPE=ins[;\t]/||m/TYPE=mnp[;\t]/))){$_="";}' \
# ${combineVcf}.tmp.allelicprimitives.vcf

rm ${combineVcf}.tmp.allelicprimitives.vcf.idx

perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl Freebayes ${combineVcf}.tmp.allelicprimitives.vcf > ${combineVcf}.tmp.freebayescallerised.vcf
perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl HCaller ${haplotyperVcf} > ${combineVcf}.tmp.haplotypercallerised.vcf
#did this already on a per sample base maybe overkill to do it again
perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl MuTect2 ${mutect2Vcf} |perl  $(which VcfQssFix.pl ) /dev/stdin > ${combineVcf}.tmp.mutect2callerised.vcf

${stage} ${bcftoolsMod}
bgzip ${combineVcf}.tmp.haplotypercallerised.vcf && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.haplotypercallerised.vcf.gz > ${combineVcf}.tmp.haplotypernorm.vcf
bgzip ${combineVcf}.tmp.freebayescallerised.vcf  && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.freebayescallerised.vcf.gz  > ${combineVcf}.tmp.freebayesnorm.vcf
bgzip ${combineVcf}.tmp.mutect2callerised.vcf    && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.mutect2callerised.vcf.gz    > ${combineVcf}.tmp.mutect2norm.vcf

#merge gatk/freebayes/mutect
java -Xmx4g -Djava.io.tmpdir=${variantCombineDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T CombineVariants \
 -R ${onekgGenomeFasta} \
 --variant:GATK ${combineVcf}.tmp.haplotypernorm.vcf \
 --variant:freebayes  ${combineVcf}.tmp.freebayesnorm.vcf \
 --variant:MuTect2 ${combineVcf}.tmp.mutect2norm.vcf \
 -o ${combineVcf}.tmp.combine.vcf \
 -genotypeMergeOptions PRIORITIZE \
 -priority GATK,freebayes,MuTect2 \
 --filteredrecordsmergetype KEEP_UNCONDITIONAL

#fix genotype fields
perl -i.bak -wpe 'if(not($_ =~ m/^#/)){ my @tnew; my @t=split("\t",$_); for my $f (@t[9..$#t]){$f =~ s!^\.$!./.! if($f =~ m/^\.$/); push(@tnew,$f);}; $_=join("\t", (@t[0..8],@tnew));}' ${combineVcf}.tmp.combine.vcf


cp ${combineVcf}.tmp.combine.vcf ${combineVcf}.tmp.selectGatk.vcf

#skip prio gatk
#perl $EBROOTPIPELINEMINUTIL/bin/filterCombinedVariantsForGatk.pl \
# ${combineVcf}.tmp.combine.vcf > ${combineVcf}.tmp.selectGatk.vcf

perl $EBROOTPIPELINEMINUTIL/bin/RecoverSampleAnnotationsAfterCombineVariants.pl \
 ${combineVcf}.tmp.complex.vcf \
 ${combineVcf}.tmp.combine.vcf \
 ${combineVcf}.tmp.haplotypernorm.vcf \
 ${combineVcf}.tmp.freebayesnorm.vcf \
 ${combineVcf}.tmp.mutect2norm.vcf \
 > ${combineVcf}.tmp.annotNoComplex.vcf

#java -jar ${EBROOTGATK}/GenomeAnalysisTK.jar \
# -T HaplotypeCaller \
# -R ftp.broadinstitute.org/bundle/2.8/b37/human_g1k_v37_decoy.fasta \
# --activeRegionExtension 200 \
# --activeRegionMaxSize 200 \
# --genotyping_mode GENOTYPE_GIVEN_ALLELES \
# --alleles complexmerge.vcf \
# -o complexmerge.HCcalled.vcf \
# --output_mode EMIT_ALL_SITES \
# --forceActive \
#-L complexmerge.vcf \
#-I all.bam \
# --standard_min_confidence_threshold_for_calling 0

# sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n' "${bqsrBam[@]}" | sort -u ))

inputs=$(printf ' -I %s ' $(printf '%s\n' ${bams[@]}))

java -Xmx8g -Djava.io.tmpdir=${variantCombineDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T HaplotypeCaller \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf}\
 $inputs \
 --max_alternate_alleles 9 \
 --activeRegionExtension 200 \
 --activeRegionMaxSize 200 \
 --genotyping_mode GENOTYPE_GIVEN_ALLELES \
 --alleles ${combineVcf}.tmp.complex.vcf \
 --output_mode EMIT_ALL_SITES \
 --forceActive \
 -stand_call_conf 0 \
 -L ${combineVcf}.tmp.complex.vcf \
 -o ${combineVcf}.tmp.complexHCregeno.vcf

bgzip ${combineVcf}.tmp.complexHCregeno.vcf && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.complexHCregeno.vcf.gz    > ${combineVcf}.tmp.complexHCregeno.norm.vcf

perl $EBROOTPIPELINEMINUTIL/bin/RecoverSampleAnnotationsAfterCombineVariants.pl \
 ${combineVcf}.tmp.ReallyComplex.vcf \
 ${combineVcf}.tmp.annotNoComplex.vcf \
 ${combineVcf}.tmp.complexHCregeno.norm.vcf \
 > ${combineVcf}

#fear the complex variants
grep -vPc "^#" ${combineVcf}.tmp.ReallyComplex.vcf
tail  ${combineVcf}.tmp.ReallyComplex.vcf

mv ${combineVcf}.tmp.ReallyComplex.vcf ${combineVcf}.ReallyComplex.vcf
mv ${combineVcf}.tmp.complex.vcf ${combineVcf}.complex.vcf

#rm -v ${combineVcf}.tmp.*.vcf

putFile ${combineVcf}
#putFile ${combineVcfIdx}

echo "## "$(date)" ##  $0 Done "
