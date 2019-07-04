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
#string freebayesProjectBam
#string freebayesMod

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
${stage} ${freebayesMod}
${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${variantCombineDir}

#
#java -Xmx4g -Djava.io.tmpdir=${variantCombineDir} \
#  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
# -T VariantsToAllelicPrimitives \
# -R ${onekgGenomeFasta} \
# -V  ${freebayesVcf} \
# -o ${combineVcf}.tmp.allelicprimitives.vcf

#remove complex snps from freebayes: depeciated because larger project will combine adjecent overlapping indels/snps into one and mark them as complex. Missing variants. 
#perl -i.bak -wpe 'if(not((m/^#/) ||  (m/TYPE=complex[;\t]/||m/TYPE=snp[;\t]/||m/TYPE=del[;\t]/||m/TYPE=ins[;\t]/||m/TYPE=mnp[;\t]/))){$_="";}' \
# ${combineVcf}.tmp.allelicprimitives.vcf

#rm ${combineVcf}.tmp.allelicprimitives.vcf.idx

perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl Freebayes ${freebayesVcf} > ${combineVcf}.tmp.freebayescallerised.vcf
perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl HCaller ${haplotyperVcf} > ${combineVcf}.tmp.haplotypercallerised.vcf
#did this already on a per sample base maybe overkill to do it again
perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl MuTect2 ${mutect2Vcf} |perl  $(which VcfQssFix.pl ) /dev/stdin > ${combineVcf}.tmp.mutect2callerised.vcf

${stage} ${bcftoolsMod}
bgzip -c ${combineVcf}.tmp.haplotypercallerised.vcf > ${combineVcf}.tmp.haplotypercallerised.vcf.gz && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.haplotypercallerised.vcf.gz > ${combineVcf}.tmp.haplotypernorm.vcf
bgzip -c ${combineVcf}.tmp.freebayescallerised.vcf  > ${combineVcf}.tmp.freebayescallerised.vcf.gz  && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.freebayescallerised.vcf.gz  > ${combineVcf}.tmp.freebayesnorm.vcf
bgzip -c ${combineVcf}.tmp.mutect2callerised.vcf    > ${combineVcf}.tmp.mutect2callerised.vcf.gz    && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.mutect2callerised.vcf.gz    > ${combineVcf}.tmp.mutect2norm.vcf

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

if [ -e "${combineVcf}.tmp.complex.vcf" ] ; then
	echo "## INFO ## Cleaning up old run file ${combineVcf}.tmp.complex.vcf" 
	rm -v ${combineVcf}.tmp.complex.vcf
fi

perl $EBROOTPIPELINEMINUTIL/bin/RecoverSampleAnnotationsAfterCombineVariantsByPosWalk.pl \
 ${combineVcf}.tmp.complex.vcf \
 ${combineVcf}.tmp.combine.vcf \
 ${combineVcf}.tmp.haplotypernorm.vcf \
 ${combineVcf}.tmp.freebayesnorm.vcf \
 ${combineVcf}.tmp.mutect2norm.vcf \
 > ${combineVcf}.tmp.annotNoComplex.vcf



if [ -s ${combineVcf}.tmp.complex.vcf ] ; then
	#${combineVcf}.tmp.annotNoComplex.vcf
	
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

	#freebayes -f ${onekgGenomeFasta} -@  ${combineVcf}.tmp.complex.vcf ${freebayesProjectBam} > ${combineVcf}.tmp.complexregeno.vcf
	# or
	java -Xmx16g -Djava.io.tmpdir=${variantCombineDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
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
	 -o ${combineVcf}.tmp.complexregeno.vcf
	
	bgzip -c  ${combineVcf}.tmp.complexregeno.vcf > ${combineVcf}.tmp.complexregeno.vcf.gz && bcftools norm -m -any -f ${onekgGenomeFasta} ${combineVcf}.tmp.complexregeno.vcf.gz    > ${combineVcf}.tmp.complexregeno.norm.vcf
	
	if [ -e "${combineVcf}.tmp.ReallyComplex.vcf" ] ; then 
	        echo "## INFO ## Cleaning up old run file ${combineVcf}.tmp.ReallyComplex.vcf"
	        rm -v ${combineVcf}.tmp.ReallyComplex.vcf
	fi

	perl $EBROOTPIPELINEMINUTIL/bin/RecoverSampleAnnotationsAfterCombineVariantsByPosWalk.pl \
	 ${combineVcf}.tmp.ReallyComplex.vcf \
	 ${combineVcf}.tmp.annotNoComplex.vcf \
	 ${combineVcf}.tmp.complexregeno.norm.vcf \
	 > ${combineVcf}

	#fear the complex variants
	grep -vPc "^#" ${combineVcf}.tmp.ReallyComplex.vcf|| echo "## no errors here!! Yaay!!"
	tail  ${combineVcf}.tmp.ReallyComplex.vcf

	mv ${combineVcf}.tmp.ReallyComplex.vcf ${combineVcf}.ReallyComplex.vcf

	mv ${combineVcf}.tmp.complex.vcf ${combineVcf}.complex.vcf
else
	#the poswalk script cannot produce complex subfile so this is a shorter workaround
	mv ${combineVcf}.tmp.annotNoComplex.vcf  ${combineVcf}
fi
#rm -v ${combineVcf}.tmp.*.vcf

putFile ${combineVcf}
#putFile ${combineVcfIdx}

echo "## "$(date)" ##  $0 Done "
