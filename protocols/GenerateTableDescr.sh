#MOLGENIS walltime=23:59:00 mem=1gb ppn=1

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir
#string onekgGenomeFasta

#string vcf

#string tableDir
#string descrTable
#string vcfToolsMod
#string GenerateTableDescriptionByVcfHeaderPl

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${descrTable}" 

for file in "${vcf}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

${stage} ${vcfToolsMod}
${checkStage}

set -x
set -e

mkdir -p ${tableDir}


perl ${GenerateTableDescriptionByVcfHeaderPl} ${vcf} > ${descrTable}

putFile ${descrTable}

echo "## "$(date)" ##  $0 Done "
