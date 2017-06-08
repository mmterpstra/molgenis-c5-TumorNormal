#MOLGENIS walltime=23:59:00 mem=8gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod
#string freebayesMod
#string onekgGenomeFasta
##list bqsrBam,bqsrBai
#string freebayesProjectBam
#string freebayesProjectBai
#string targetsList
#string scatterList
#string freebayesDir
#string freebayesScatVcf

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${freebayesScatVcf}" 

for file in "${freebayesProjectBam}" "${freebayesProjectBam}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${freebayesMod}
${checkStage}

set -x
set -e


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


	InterValOperand=" -t ${scatterList}.bed "

fi

mkdir -p ${freebayesDir}

#freebayes -t targets.bed --allele-balance-priors-off --binomial-obs-priors-off --hwe-priors-off --strict-vcf --vcf out.vcf  -b b1.bam --fasta-reference fsata  
#freebayes/1.1.0-foss-2016a


freebayes \
 --fasta-reference ${onekgGenomeFasta} \
 --allele-balance-priors-off \
 --binomial-obs-priors-off \
 --hwe-priors-off \
 --min-mapping-quality 20 \
 --strict-vcf \
 --vcf ${freebayesScatVcf} \
 $InterValOperand \
 -b ${freebayesProjectBam} \
 --use-best-n-alleles 4\


# -dontUseSoftClippedBases \

putFile ${freebayesScatVcf}
#putFile ${freebayesScatVcfIdx}

echo "## "$(date)" ##  $0 Done "
