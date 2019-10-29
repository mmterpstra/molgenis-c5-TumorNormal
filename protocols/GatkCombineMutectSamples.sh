#MOLGENIS walltime=23:59:00 mem=4gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string pipelineUtilMod
#string gatkMod
#string onekgGenomeFasta

##the following parameters select for control samples also. To remove this bias cleaner merging needs to be done
#list mutect2SampleVcf
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
	normal=$(perl -wpe  's/.*.t_.*.n_(.*).00.*/$1/g' <(echo ${v}))
	inputs=$(echo -n "$inputs -V:$tumor $v")
	if [ -z "$prio" ]; then
		prio="$tumor"
	else
		if [ $(echo $prio| grep -c "^$tumor,\|,$tumor,\|,$tumor\$\|^$tumor\$") -gt 0 ] ; then
			if [ "x$tumor" -eq "x$normal" ]; then
				prio="$prio,${tumor}2"
			else
				prio="${tumor}2,$prio"
			fi
		else
			if [ "x$tumor" -eq "x$normal" ]; then
				prio="$prio,${tumor}"
			else
				prio="${tumor},$prio"
			fi
		fi
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
 -o ${mutect2Vcf}.tmp.vcf \
 -genotypeMergeOptions PRIORITIZE \
 -priority $prio \
 --filteredrecordsmergetype KEEP_IF_ANY_UNFILTERED

perl $EBROOTPIPELINEMINUTIL/bin/RecoverSampleAnnotationsAfterCombineVariantsByPosWalk.pl \
         ${mutect2Vcf}.tmp.ReallyComplex.vcf \
         ${mutect2Vcf}.tmp.vcf \
         $(printf '%s\n' "${mutect2SampleVcf[@]}" | sort -u ) \
         > ${mutect2Vcf}


putFile ${mutect2Vcf}
#putFile ${mutect2VcfIdx}

echo "## "$(date)" ##  $0 Done "
