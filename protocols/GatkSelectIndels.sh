#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string gatkMod
#string onekgGenomeFasta
#string custAnnotVcf
#string custAnnotVcfIdx
#string variantFiltDir
#string indelMnpRawVcf
#string indelMnpRawVcfIdx
#string indelMnpVcf
#string indelMnpVcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${indelMnpVcf}" \
"${indelMnpVcfIdx}"

for file in "${onekgGenomeFasta}" "${custAnnotVcf}" "${custAnnotVcfIdx}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${variantFiltDir}

java -Xmx4g -Djava.io.tmpdir=${variantFiltDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T SelectVariants \
 -R ${onekgGenomeFasta} \
 --variant:vcf ${custAnnotVcf} \
 -o ${indelMnpRawVcf} \
 -L:VCF ${custAnnotVcf} \
 --selectTypeToExclude SNP 

java -Xmx4g -Djava.io.tmpdir=${variantFiltDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T VariantFiltration \
 -R ${onekgGenomeFasta} \
 --variant:VCF ${indelMnpRawVcf} \
 -o ${indelMnpVcf} \
 --filterExpression "QUAL < 20"  --filterName "LowQual" \
 --filterExpression "vc.hasAttribute('ReadPosRankSum') && ReadPosRankSum < -20.0"  --filterName "ReadPosRankSumlt-20" \
 --filterExpression "FS > 200.0"  --filterName "FSgt200" \
 --filterExpression "vc.hasAttribute('RPA') &&(vc.getAttribute('RPA').0 > 8||vc.getAttribute('RPA').1 > 8||vc.getAttribute('RPA').2 > 8)"  --filterName "RPAgt8" \
 --filterExpression "vc.hasAttribute('TeMeermanAlleleBias') && TeMeermanAlleleBias > 5.0"  --filterName "TeMeermanAlleleBiasgt5" \
 --filterExpression "!( vc.hasAttribute('IsChangeInTumor'))"  --filterName "NotPolymorfic" \
 --filterExpression "!((vc.hasAttribute('SNPEFFANN_ANNOTATION_IMPACT') && vc.getAttribute('SNPEFFANN_ANNOTATION_IMPACT').contains('HIGH'))||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('missense_variant'))||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('coding_sequence_variant'))||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('inframe_insertion'))||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('disruptive_inframe_insertion'))||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('inframe_deletion'))||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('disruptive_inframe_deletion')))" \
 --filterName "NotPutatativeHarmfulVariant" \
 --filterExpression "(vc.hasAttribute('1000gPhase1Indels.AF') && (vc.getAttribute('1000gPhase1Indels.AF') > 0.02&&vc.getAttribute('1000gPhase1Indels.AF') < 0.98))" --filterName "1000gMAFgt0.02" \
 --filterExpression "(vc.hasAttribute('1000gPhase1Indels.EUR_AF') && (vc.getAttribute('1000gPhase1Indels.EUR_AF') > 0.02&&vc.getAttribute('1000gPhase1Indels.EUR_AF') < 0.98))" --filterName "1000gPhase1Indels.EUR_AF0.02" \
 --filterExpression "(vc.hasAttribute('1000gPhase1Indels.AFR_AF') && (vc.getAttribute('1000gPhase1Indels.AFR_AF') > 0.02&&vc.getAttribute('1000gPhase1Indels.AFR_AF') < 0.98))" --filterName "1000gAFRMAFgt0.02" \
 --filterExpression "(vc.hasAttribute('1000gPhase1Indels.AMR_AF') && (vc.getAttribute('1000gPhase1Indels.AMR_AF') > 0.02&&vc.getAttribute('1000gPhase1Indels.AMR_AF') < 0.98))" --filterName "1000gAMRMAFgt0.02" \
 --filterExpression "(vc.hasAttribute('1000gPhase1Indels.ASN_AF') && (vc.getAttribute('1000gPhase1Indels.ASN_AF') > 0.02&&vc.getAttribute('1000gPhase1Indels.ASN_AF') < 0.98))" --filterName "1000gASNMAFgt0.02" \
 --filterExpression "QD < 2.0 && vc.hasAttribute('AF') && QD / AF < 8.0"  --filterName "QDlt2andQdbyAflt8"

putFile ${indelMnpVcf}
putFile ${indelMnpVcfIdx}

rm ${indelMnpRawVcf} ${indelMnpRawVcfIdx}

echo "## "$(date)" ##  $0 Done "
