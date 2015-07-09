#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir

#string gatkVersion
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
${stage} GATK/${gatkVersion}
${checkStage}

set -x
set -e

mkdir -p ${variantFiltDir}

java -Xmx4g -Djava.io.tmpdir=${variantFiltDir} \
 -jar $GATK_HOME/GenomeAnalysisTK.jar \
 -T SelectVariants \
 -R ${onekgGenomeFasta} \
 --variant:vcf ${custAnnotVcf} \
 -o ${indelMnpRawVcf} \
 -L:VCF ${custAnnotVcf} \
 -selectType INDEL \
 -selectType MNP \

java -Xmx4g -Djava.io.tmpdir=${variantFiltDir} \
 -jar $GATK_HOME/GenomeAnalysisTK.jar \
 -T VariantFiltration \
 -R ${onekgGenomeFasta} \
 --variant:VCF ${indelMnpRawVcf} \
 -o ${indelMnpVcf} \
 --filterExpression "QUAL < 30"  --filterName "LowQual" \
 --filterExpression "QD < 2.0" --filterName "QDlt2" \
 --filterExpression "vc.hasAttribute('ReadPosRankSum') && ReadPosRankSum < -20.0"  --filterName "ReadPosRankSumlt-20" \
 --filterExpression "FS > 200.0"  --filterName "FSgt200" \
 --filterExpression "vc.hasAttribute('RPA') &&(vc.getAttribute('RPA').0 > 8||vc.getAttribute('RPA').1 > 8||vc.getAttribute('RPA').2 > 8)"  --filterName "RPAgt8" \
 --filterExpression "vc.hasAttribute('TeMeermanAlleleBias') && TeMeermanAlleleBias > 5.0"  --filterName "TeMeermanAlleleBiasgt5" \
 --filterExpression "!( vc.hasAttribute('IsChangeInTumor'))"  --filterName "NotPolymorfic" \
 --filterExpression "!((vc.hasAttribute('SNPEFF_IMPACT') && vc.getAttribute('SNPEFF_IMPACT').equals('HIGH'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('NON_SYNONYMOUS_CODING'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_INSERTION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE_PLUS_CODON_INSERTION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_DELETION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE_PLUS_CODON_DELETION')))" \
 --filterName "NotPutatativeHarmfulVariant" \
 --filterExpression "(vc.hasAttribute('1000gPhase1Indels.AF') && (vc.getAttribute('1000gPhase1Indels.AF') > 0.02&&vc.getAttribute('1000gPhase1Indels.AF') < 0.98))" --filterName "1000gMAFgt0.02" \
 --filterExpression "(vc.hasAttribute('1000gPhase1Indels.EUR_AF') && (vc.getAttribute('1000gPhase1Indels.EUR_AF') > 0.02&&vc.getAttribute('1000gPhase1Indels.EUR_AF') < 0.98))" --filterName "1000gPhase1Indels.EUR_AF0.02" \
 --filterExpression "QD < 2.0 && vc.hasAttribute('AF') && QD / AF < 8.0"  --filterName "QDlt2andQdbyAflt8

putFile ${indelMnpVcf}
putFile ${indelMnpVcfIdx}

rm ${indelMnpRawVcf} ${indelMnpRawVcfIdx}

echo "## "$(date)" ##  $0 Done "
