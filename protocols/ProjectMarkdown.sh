#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project
#string projectDir

#string RMod
#string RmarkMod
#string stage
#string checkStage

#list sampleMarkdown
#string projectMarkdown

alloutputsexist \
 ${projectMarkdown} \
 ${projectMarkdown}.html \

echo "## "$(date)" Start $0"

#load modules
${stage} ${RmarkMod}

${checkStage}

set -x
set -e

#get samplemarkdown
mds=($(printf '%s\n' "${sampleMarkdown[@]}" | sort -u ))

vcflist=

for md in "${mds[@]}"; do
	getFile $file
	if [ -e $md ]; then
		echo "added $md to merge list";
		mdlist=("${mdlist[@]}" "$md")
	fi
done


#main and collect data

#fastq table

ls "${mdlist[@]}"

#alignment metrics

#multiple metrics

#hsmetrics

#vcf metrics??


echo "## "$(date)" ##  $0 Done "
