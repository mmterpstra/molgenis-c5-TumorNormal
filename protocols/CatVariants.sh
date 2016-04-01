#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string gatkMod
#string onekgGenomeFasta
#string haplotyperDir
#list haplotyperScatVcf,haplotyperScatVcfIdx
#string haplotyperVcf
#string haplotyperVcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${haplotyperVcf}" \
"${haplotyperVcfIdx}"

for file in "${haplotyperScatVcf[@]}" "${haplotyperScatVcfIdx[@]}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${checkStage}

set -x
set -e

#pseudo
#java -cp GenomeAnalysisTK.jar org.broadinstitute.gatk.tools.CatVariants \
#    -R ref.fasta \
#    -V input1.vcf \
#    -V input2.vcf \
#    -out output.vcf \
#    -assumeSorted
vcfs=($(printf '%s\n' "${haplotyperScatVcf[@]}" | sort -u ))

inputs=$(printf ' -V %s ' $(printf '%s\n' ${vcfs[@]}))


java -Xmx4g -Djava.io.tmpdir=${haplotyperDir} -cp $EBROOTGATK/GenomeAnalysisTK.jar org.broadinstitute.gatk.tools.CatVariants \
    -R ${onekgGenomeFasta} \
    $inputs \
    -out ${haplotyperVcf}
    

putFile ${haplotyperVcf}
putFile ${haplotyperVcfIdx}

echo "## "$(date)" ##  $0 Done "
