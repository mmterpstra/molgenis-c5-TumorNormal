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
#string mutect2PonDir
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
        normal=$(perl -wpe  's/.*.t_.*.n_(.*)\.0\d+.*/$1/g' <(echo ${v}))
        inputs=$(echo -n "$inputs -V:$tumor $v")
        if [ -z "$prio" ]; then
                prio="$tumor"
        else
            	count=0
                if [ $(echo $prio|perl -wpe 's/,/,\n,/g'| grep -c "^$tumor,\|,$tumor,\|,$tumor\$\|^$tumor\$") -ne 0 ]; then

                        count=$( echo $prio|perl -wpe 's/,/,\n,/g'| grep -c "^$tumor,\|,$tumor,\|,$tumor\$\|^$tumor\$\|^$tumor[123456789],\|,$tumor[123456789],\|,$tumor[123456789]\$\|^$tumor[123456789]\$"  )
                fi
		
		#countofinputs=0
		#if [ $(echo $prio|perl -wpe 's/,/,\n,/g'| grep -c "^$tumor,\|,$tumor,\|,$tumor\$\|^$tumor\$") -ne 0 ]; then
			
		

                if [ $count -ge 1 ] ; then
                        suffix=0
                        let suffix=count+1

                        if [ "x$tumor" == "x$normal" ]; then
                                prio="$prio,${tumor}${suffix}"
                        else
                                prio="${tumor}${suffix},$prio"
                        fi
                else
                    	if [ "x$tumor" == "x$normal" ]; then
                                prio="$prio,${tumor}"
                        else
                            	prio="${tumor},$prio"
                        fi
                fi
        fi
done

echo 'prio='$prio';'


#for v in ${vcfs[@]}; do
#        tumor=$(perl -wpe  's/.*.t_(.*).n_.*/$1/g' <(echo ${v}))
#        normal=$(perl -wpe  's/.*.t_.*.n_(.*)\.0\d+.*/$1/g' <(echo ${v}))
#        if [ $(echo $prio| grep -c "^$normal,\|,$normal,\|,$normal\$\|^$normal\$" || true) -eq 0 ] ; then
#                prio="${prio},${normal}"
#       	else
#		count=0
#		#f [ $(echo $prio|perl -wpe 's/,/,\n,/g'| grep -c "^$tumor,\|,$tumor,\|,$tumor\$\|^$tumor\$") -ne 0 ]; then
#		count=$( echo $prio|perl -wpe 's/,/,\n,/g'| grep -c "^$normal,\|,$normal,\|,$normal\$\|^$normal\$\|^$normal[123456789],\|,$normal[123456789],\|,$normal[123456789]\$\|^$normal[123456789]\$"  )
#		suffix=0
#		let suffix=count+1
#		prio="$prio,${normal}${suffix}"
#	fi
#done

echo "inputs="$inputs";"
echo 'prio='$prio';'

minimumNOption=""
if [ "$(dirname ${mutect2Vcf})" -eq  "${mutect2PonDir}" ]; then
	echo "## INFO ## Assumed to be working on mutect pon files so setting the minimumN option";
	minimumNOption="--minimumN 3"

fi
#merge gatk/freebayes
java -Xmx4g -Djava.io.tmpdir=${mutect2Dir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T CombineVariants \
 -R ${onekgGenomeFasta} \
 $inputs \
 -o ${mutect2Vcf}.tmp.vcf \
 -genotypeMergeOptions PRIORITIZE \
 -priority $prio \
 --filteredrecordsmergetype KEEP_IF_ANY_UNFILTERED \
 ${minimumNOption}


if grep -v '^#' ${mutect2Vcf}.tmp.vcf -c ; then
perl $EBROOTPIPELINEMINUTIL/bin/RecoverSampleAnnotationsAfterCombineVariantsByPosWalk.pl \
         ${mutect2Vcf}.tmp.ReallyComplex.vcf \
         ${mutect2Vcf}.tmp.vcf \
         $(printf '%s\n' "${mutect2SampleVcf[@]}" | sort -u ) \
         > ${mutect2Vcf}
else
	cp ${mutect2Vcf}.tmp.vcf ${mutect2Vcf}
fi

putFile ${mutect2Vcf}
#putFile ${mutect2VcfIdx}

echo "## "$(date)" ##  $0 Done "
