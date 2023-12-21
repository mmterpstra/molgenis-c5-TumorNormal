#MOLGENIS walltime=5:59:00 mem=4gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string pipelineUtilMod
#string gatkMod
#string onekgGenomeFasta

##the following parameters select for control samples also. To remove this bias cleaner merging needs to be done
#list controlSamplesVcf
#string sampleVcfDir
#string sampleVcf
#string sampleVcfIdx

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${sampleVcf}" \
"${sampleVcfIdx}" 

for file in "${onekgGenomeFasta}" "${controlSamplesVcf[@]}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${pipelineUtilMod}
${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${sampleVcfDir}

vcfs=($(printf '%s\n' "${controlSamplesVcf[@]}" | sort -u ))
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
#minimumNOption="--minimumN 2"

#merge gatk/freebayes
java -Xmx4g -Djava.io.tmpdir=${sampleVcfDir} \
  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T CombineVariants \
 -R ${onekgGenomeFasta} \
 $inputs \
 -o ${sampleVcf}.tmp.vcf \
 -genotypeMergeOptions PRIORITIZE \
 -priority $prio \
 --filteredrecordsmergetype KEEP_IF_ANY_UNFILTERED \
 ${minimumNOption}


if grep -v '^#' ${sampleVcf}.tmp.vcf -c ; then
perl $EBROOTPIPELINEMINUTIL/bin/RecoverSampleAnnotationsAfterCombineVariantsByPosWalk.pl \
         ${sampleVcf}.tmp.ReallyComplex.vcf \
         ${sampleVcf}.tmp.vcf \
         $(printf '%s\n' "${controlSamplesVcf[@]}" | sort -u ) \
         > ${sampleVcf}
else
	cp ${sampleVcf}.tmp.vcf ${sampleVcf}
fi

putFile ${sampleVcf}
#putFile ${sampleVcfIdx}

echo "## "$(date)" ##  $0 Done "
