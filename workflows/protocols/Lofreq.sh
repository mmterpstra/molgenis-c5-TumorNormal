#MOLGENIS nodes=1 ppn=1 mem=2gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string lofreqMod
#string samtoolsMod
#string onekgGenomeFasta
#string targetsList
#string cosmicVcf
#string dbsnpVcf
#string scatterList

#string viterbiBam
#string viterbiBai
#string viterbiControlBam
#string viterbiControlBai
#string lofreqScatVcf
#string lofreqScatVcfIdx
#string lofreqDir


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${lofreqScatVcf} \
 ${lofreqScatVcfIdx}

${stage} ${samtoolsMod} ${lofreqMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${viterbiBam}
getFile ${viterbiBai}
getFile ${viterbiControlBam}
getFile ${viterbiControlBai}
getFile ${cosmicVcf}
getFile ${dbsnpVcf}

set -x
set -e

#if the script has managed to run until thispoint it is likely that A) the output still isn't set correctly and B) this didn't ran correctly is it is advised to remove the output files if present.
if [ -n "$(ls -A ${lofreqScatVcf}*)" ]; then
	rm -v ${lofreqScatVcf}*
fi 

suffix=""
#try to run on gzipped input if possible
if [ $(basename ${dbsnpVcf} .gz) == $(basename ${dbsnpVcf}) ]; then 
	suffix=".gz"
fi

mkdir -p ${lofreqDir}
#if has targets use targets list
if [ ${#targetsList} -ne 0 ]; then

        getFile ${scatterList}
        #convert to bedfile
        grep -v '^@' ${scatterList} | perl -wlane 'print join("\t",($F[0],$F[1]-1,$F[2],$.));' >  $(ls ${scatterList}).bed
        if [ ! -e ${scatterList} ]; then
                line="skipping this freebayes because not -e ${scatterList}"

                echo $line 1>&2
                if [ -e $ENVIRONMENT_DIR/${taskId}.sh ]; then
                        touch $ENVIRONMENT_DIR/${taskId}.sh.finished
                        touch $ENVIRONMENT_DIR/${taskId}.env
                fi
                exit 0;
        fi


	InterValOperand=" -l ${scatterList}.bed "

fi


Normalspec=""

#normalspec run only when they aren't the same bam/sample
if [ ${viterbiBam} !=  ${viterbiControlBam} ]; then
	#run with controlsample
        echo "## "$(date)" ##  $0 Running with controlsample '${viterbiControlBam}'."
	
	Normalspec=" -n ${viterbiControlBam} "
fi


#lofreq somatic -n n.bam -t t.bam -o out.pref -f ref.fa --cal-indels -l reg.bed -d DBSNP.vcf --threads NUM_THREADS
lofreq somatic \
 ${Normalspec} \
 -t ${viterbiBam} \
 -o ${lofreqScatVcf} \
 -f ${onekgGenomeFasta} \
 --call-indels \
 ${InterValOperand} \
 -d ${dbsnpVcf}${suffix} \
 --threads 1

touch ${lofreqScatVcf}
putFile ${lofreqScatVcf}


echo "## "$(date)" ##  $0 Done "
