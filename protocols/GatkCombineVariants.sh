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
#string mutect2Vcf

#string variantCombineDir
#string combineVcf
#string combineVcfIdx

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

perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl freebayes 

#
java -Xmx4g -Djava.io.tmpdir=${variantCombineDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T VariantsToAllelicPrimitives \
 -R ${onekgGenomeFasta} \
 -V  ${freebayesVcf} \
 -o ${freebayesVcf}.allelicprimitives.vcf

perl -i.bak -wpe 'if(not((m/^#/) ||  (m/TYPE=complex[;\t]/||m/TYPE=snp[;\t]/||m/TYPE=del[;\t]/||m/TYPE=ins[;\t]/||m/TYPE=mnp[;\t]/))){$_="";}' \
 ${freebayesVcf}.allelicprimitives.vcf

rm ${freebayesVcf}.allelicprimitives.vcf.idx

perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl freebayes ${freebayesVcf}.allelicprimitives.vcf > ${freebayesVcf}.callerised.vcf
perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl HCcaller ${haplotyperVcf} > ${haplotyperVcf}.callerised.vcf
perl $EBROOTPIPELINEMINUTIL/bin/CalleriseVcf.pl MuTect2 ${mutect2Vcf} > ${mutect2Vcf}.callerised.vcf



#merge gatk/freebayes/mutect
java -Xmx4g -Djava.io.tmpdir=${variantCombineDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T CombineVariants \
 -R ${onekgGenomeFasta} \
 --variant:GATK ${haplotyperVcf}.callerised.vcf \
 --variant:freebayes  ${freebayesVcf}.callerised.vcf \
 --variant:MuTect2 ${mutect2Vcf}.callerised.vcf \
 -o ${combineVcf}.tmp.vcf \
 -genotypeMergeOptions PRIORITIZE \
 -priority GATK,freebayes,MuTect2 \
 --filteredrecordsmergetype KEEP_UNCONDITIONAL

perl $EBROOTPIPELINEMINUTIL/bin/filterCombinedVariantsForGatk.pl \
 ${combineVcf}.tmp.vcf > ${combineVcf}

rm -v ${combineVcf}.tmp.vcf

perl -i.bak -wpe 'if(not($_ =~ m/^#/)){ my @tnew; my @t=split("\t",$_); for my $f (@t[9..$#t]){$f =~ s!^\.$!./.! if($f =~ m/^\.$/); push(@tnew,$f);}; $_=join("\t", (@t[0..8],@tnew));}' ${combineVcf}


putFile ${combineVcf}
#putFile ${combineVcfIdx}

echo "## "$(date)" ##  $0 Done "
