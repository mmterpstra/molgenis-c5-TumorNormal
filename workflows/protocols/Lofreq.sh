#MOLGENIS nodes=1 ppn=1 mem=2gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string lofreqMod
#string samtoolsMod
#string picardMod
#string pipelineUtilMod
#string onekgGenomeFasta
#string targetsList
#string cosmicVcf
#string dbsnpVcf
#string scatterList

#string viterbiBam
#string viterbiBai
#string viterbiControlBam
#string viterbiControlBai
#string sampleName
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

	lofreq somatic \
	 ${Normalspec} \
	 -t ${viterbiBam} \
	 -o ${lofreqScatVcf} \
	 -f ${onekgGenomeFasta} \
	 --call-indels \
	 ${InterValOperand} \
	 -d ${dbsnpVcf}${suffix} \
	 --threads 1
	
	
	(${stage} ${pipelineUtilMod}
		#fixup by moving stuff to the genotype fields and adding general fields (AD/GT)
		for i in tumor_stringent.indels.vcf.gz tumor_stringent.snvs.vcf.gz somatic_final.snvs.vcf.gz somatic_final.indels.vcf.gz; do
			perl -wpe 's/^##fileformat=VCFv4\.0$/##fileformat=VCFv4.2/;
				if($_ =~ /^#CHROM/){
					print "##INFO=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n##INFO=<ID=AD,Number=2,Type=Integer,Description=\"Allelic depths for the ref and alt alleles in the order listed\">\n##INFO=<ID=UNIQ,Number=0,Type=Flag,Description=\"Unique, i.e. not detectable in paired sample\">\n##INFO=<ID=UQ,Number=1,Type=Integer,Description=\"Phred-scaled uniq score at this position\">\n##INFO=<ID=SOMATIC,Number=0,Type=Flag,Description=\"Somatic event\">\n";}
				if(m/DP4=(\d+(,\d+){3})(;|\n)/){
					my @dp4=split(",",$1);
					$_=substr($_,0,-1).";AD=".($dp4[0]+$dp4[1]).",".($dp4[2]+$dp4[3])."\n";
					if($dp4[0]+$dp4[1]> 0){
						$_=substr($_,0,-1).";GT=0/1\n";
					}else{
						$_=substr($_,0,-1).";GT=1/1\n";
					}
				};' <(zcat ${lofreqScatVcf}${i} ) > ${lofreqScatVcf}$(basename ${i} .vcf.gz).tmp.fixed.vcf
			InfoFieldsToGenotypeFields.pl -f 'GT,AD,DP,DP4,AF,SB' -g "${sampleName}" -i ${lofreqScatVcf}$(basename ${i} .vcf.gz).tmp.fixed.vcf > ${lofreqScatVcf}$(basename ${i} .vcf.gz).fixed.vcf;
		done; )
	#Merge tumor calls to one VCF 
	(${stage} ${picardMod}
		java -jar $EBROOTPICARD/picard.jar SortVcf \
			SD=/data/umcg-mterpstra/apps/data/ftp.broadinstitute.org/bundle/bundle17jan2020/hg38/Homo_sapiens_assembly38.fasta.dict \
			I=${lofreqScatVcf}tumor_stringent.indels.fixed.vcf I=${lofreqScatVcf}tumor_stringent.snvs.fixed.vcf \
			O=${lofreqScatVcf}tumor_stringent.fixed.vcf)
	if [ "$(grep -vc '^#' ${combineVcf}.tmp.annotNoComplex.vcf)" = "0" ]; then
		#Annotate tumor calls with somatic info
		(${stage} ${pipelineUtilMod}
		 RecoverSampleAnnotationsAfterCombineVariantsByPosWalk.pl ${lofreqScatVcf}_tumor_complex.vcf ${lofreqScatVcf}tumor_stringent.fixed.vcf ${lofreqScatVcf}somatic_final.indels.fixed.vcf ${lofreqScatVcf}somatic_final.snvs.fixed.vcf 1> ${lofreqScatVcf})
	else
		cp ${lofreqScatVcf}tumor_stringent.fixed.vcf ${lofreqScatVcf}
	fi

else
	#run lofreq only
	lofreq call ${viterbiBam} \
	 -o ${lofreqScatVcf}.raw.vcf \
	 -f ${onekgGenomeFasta} \
	 --call-indels \
	 -d ${dbsnpVcf}${suffix} \
	 ${InterValOperand}
	
	#fix single sample lofreq vcf by adding general annotations
	perl -wpe 's/^##fileformat=VCFv4\.0$/##fileformat=VCFv4.2/;
		if($_ =~ /^#CHROM/){
								print "##INFO=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n##INFO=<ID=AD,Number=2,Type=Integer,Description=\"Allelic depths for the ref and alt alleles in the order listed\">\n##INFO=<ID=UNIQ,Number=0,Type=Flag,Description=\"Unique, i.e. not detectable in paired sample\">\n##INFO=<ID=UQ,Number=1,Type=Integer,Description=\"Phred-scaled uniq score at this position\">\n##INFO=<ID=SOMATIC,Number=0,Type=Flag,Description=\"Somatic event\">\n";}
		if(m/DP4=(\d+(,\d+){3})(;|\n)/){
			my @dp4=split(",",$1);
			$_=substr($_,0,-1).";AD=".($dp4[0]+$dp4[1]).",".($dp4[2]+$dp4[3])."\n";
			if($dp4[0]+$dp4[1]> 0){
				$_=substr($_,0,-1).";GT=0/1\n";
			}else{
				$_=substr($_,0,-1).";GT=1/1\n";
			}
		};' ${lofreqScatVcf}.raw.vcf > ${lofreqScatVcf}.nogenotype.vcf
	
	#add format fields
	(${stage} ${pipelineUtilMod};
		InfoFieldsToGenotypeFields.pl -f 'GT,AD,DP,DP4,AF,SB' -g "${sampleName}" -i ${lofreqScatVcf}.nogenotype.vcf > ${lofreqScatVcf}
	)

fi


touch ${lofreqScatVcf}
putFile ${lofreqScatVcf}


echo "## "$(date)" ##  $0 Done "
