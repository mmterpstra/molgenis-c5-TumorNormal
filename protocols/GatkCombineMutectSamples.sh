#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string pipelineUtilMod
#string gatkMod
#string onekgGenomeFasta
#list mutect2SampleVcf
#string mutect2Vcf

#string mutect2Dir
#string mutect2Vcf
#string mutect2VcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${mutect2Vcf}" \
"${mutect2VcfIdx}" 

for file in "${onekgGenomeFasta}" "${mutect2SampleVcf[@]}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${pipelineUtilMod}
${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${mutect2Dir}

vcfs=($(printf '%s\n' "${mutect2SampleVcf[@]}" | sort -u ))
inputs=""
prio=""

for v in ${vcfs[@]}; do 
	
	tumor=$(perl -wpe  's/.*.t_(.*).n_.*/$1/g' <(echo ${v}))
	inputs=$(echo -n "$inputs -V:$tumor $v")
	if [ -z "$prio" ]; then
		prio="$tumor"
	else
		prio="$prio,$tumor"
	fi
done

echo "inputs="$inputs";"
echo 'prio='$prio';'
 

#merge gatk/freebayes
java -Xmx4g -Djava.io.tmpdir=${mutect2Dir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T CombineVariants \
 -R ${onekgGenomeFasta} \
 $inputs \
 -o ${mutect2Vcf} \
 -genotypeMergeOptions PRIORITIZE \
 -priority $prio \
 --filteredrecordsmergetype KEEP_IF_ANY_UNFILTERED

putFile ${mutect2Vcf}
putFile ${mutect2VcfIdx}

echo "## "$(date)" ##  $0 Done "
