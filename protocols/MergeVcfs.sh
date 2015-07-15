#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir

#string picardMod
#string onekgGenomeFasta
#string onekgGenomeFastaDict
#string haplotyperDir
#list haplotyperScatVcf,haplotyperScatVcfIdx
#string haplotyperVcf
#string haplotyperVcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${haplotyperVcf}"

for file in "${haplotyperScatVcf[@]}" "${haplotyperScatVcfIdx[@]}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${picardMod}
${checkStage}

set -x
set -e

vcfs=($(printf '%s\n' "${haplotyperScatVcf[@]}" | sort -u ))

for vcf in "${vcfs[@]}"; do
	if [ -e $vcf ]; then
		echo "added $vcf to merge list";
		vcflist=("${vcflist[@]}" "$vcf")
	fi
done

inputs=$(printf ' INPUT=%s ' $(printf '%s\n' ${vcflist[@]}))

echo $inputs

java -jar $PICARD_HOME/picard.jar picard MergeVcfs $inputs OUTPUT=${haplotyperVcf}.tmp.vcf D=${onekgGenomeFastaDict}

java -jar $PICARD_HOME/picard.jar picard SortVcf INPUT=${haplotyperVcf}.tmp.vcf OUTPUT=${haplotyperVcf} SD=${onekgGenomeFastaDict}

rm ${haplotyperVcf}.tmp.vcf
rm ${haplotyperVcf}.tmp.vcf.idx
#derp index
rm ${haplotyperVcf}.idx

putFile ${haplotyperVcf}


echo "## "$(date)" ##  $0 Done "
