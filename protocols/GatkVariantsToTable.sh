#MOLGENIS walltime=23:59:00 mem=1gb ppn=1

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir
#string onekgGenomeFasta

#string vcf

#string tableDir
#string variantTable
#string variantRawTable
#string gatkMod
#string vcfToolsMod

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${variantTable}" 

for file in "${vcf}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${stage} ${vcfToolsMod}
${checkStage}

set -x
set -e

mkdir -p ${tableDir}

fields=$(perl /gcc/tools/scripts/DumpFieldsForVariantsToTable.pl ${vcf})

java -Xmx1g -Djava.io.tmpdir=${tableDir} -jar $GATK_HOME/GenomeAnalysisTK.jar \
 -T VariantsToTable \
 -R ${onekgGenomeFasta} \
 -V ${vcf} \
 -AMD \
 -raw \
 -F CHROM -F POS -F REF -F ALT -F ID -F QUAL -F FILTER $fields \
 -o ${variantRawTable}
 
java -Xmx1g -Djava.io.tmpdir=${tableDir} -jar $GATK_HOME/GenomeAnalysisTK.jar \
 -T VariantsToTable \
 -R ${onekgGenomeFasta} \
 -V ${vcf} \
 -AMD \
 -F CHROM -F POS -F REF -F ALT -F ID -F QUAL -F FILTER $fields \
 -o ${variantTable}

putFile ${variantTable}
putFile ${variantRawTable}

echo "## "$(date)" ##  $0 Done "
