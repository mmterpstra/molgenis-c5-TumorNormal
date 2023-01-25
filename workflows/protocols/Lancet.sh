#MOLGENIS nodes=1 ppn=8 mem=16gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string lancetMod
#string samtoolsMod
#string picardMod
#string pipelineUtilMod
#string onekgGenomeFasta
#string targetsList
#string cosmicVcf
#string dbsnpVcf
#string scatterList

#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai
#string controlSampleBam
#string controlSampleBai
#string lancetScatVcf
#string lancetScatVcfIdx
#string lancetDir


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${lancetScatVcf} 


${stage} ${samtoolsMod} ${lancetMod} ${pipelineUtilMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${indelRealignmentBam}
getFile ${indelRealignmentBai}
getFile ${controlSampleBam}
getFile ${controlSampleBai}
getFile ${cosmicVcf}
getFile ${dbsnpVcf}

set -x
set -e

mkdir -p ${lancetDir}
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


	InterValOperand=" --bed ${scatterList}.bed "

fi


Normalspec=""

#normalspec run only when they aren't the same bam/sample
if [ ${indelRealignmentBam} !=  ${controlSampleBam} ]; then
	#run with controlsample
        echo "## "$(date)" ##  $0 Running with controlsample '${controlSampleBam}'."
	
	Normalspec="--normal ${controlSampleBam} "
fi

#this should override the normalspec and the data should be ran only when using Panel Of Normals generation
#if [ ! -e ${mutect2PonProjectScatVcf} ]; then
#	#
#	echo "## "$(date)" ##  $0 Running in panel of normals mode."
#
#	Normalspec=' --artifact_detection_mode '
#	
#fi

if [ ${indelRealignmentBam} !=  ${controlSampleBam} ]; then
        #run with controlsample
	lancet --tumor ${indelRealignmentBam} $Normalspec --ref ${onekgGenomeFasta} $InterValOperand --num-threads 8 > ${lancetScatVcf}.tmp.vcf
else
	#no tumoronly mode
	touch ${lancetScatVcf}..tmp.vcf
	cat <<- 'END' > ${lancetScatVcf}.tmp.vcf
		##fileformat=VCFv4.2
		##fileDate=Wed Apr 13 10:35:04 2022
		##source=lancet 1.1.0, October 18 2019
		##cmdline=lancet --tumor /scratch/umcg-mterpstra/projects/29JUL2021_7_HL_885846//indelRealignment/104103-001-018.bam --normal /scratch/umcg-mterpstra/projects/29JUL2021_7_HL_885846//indelRealignment/104103-003-007.bam --ref /data/umcg-mterpstra/apps/data//ftp.broadinstitute.org/bundle/bundle17jan2020/hg38//Homo_sapiens_assembly38.fasta --bed /scratch/umcg-mterpstra/projects/29JUL2021_7_HL_885846//scatter/temp_0001_of_12/scattered.interval_list.bed --num-threads 8 
		##reference=/data/umcg-mterpstra/apps/data//ftp.broadinstitute.org/bundle/bundle17jan2020/hg38//Homo_sapiens_assembly38.fasta
		##INFO=<ID=FETS,Number=1,Type=Float,Description="Phred-scaled p-value of the Fisher's exact test for tumor-normal allele counts">
		##INFO=<ID=SOMATIC,Number=0,Type=Flag,Description="Somatic mutation">
		##INFO=<ID=SHARED,Number=0,Type=Flag,Description="Shared mutation betweem tumor and normal">
		##INFO=<ID=NORMAL,Number=0,Type=Flag,Description="Mutation present only in the normal">
		##INFO=<ID=NONE,Number=0,Type=Flag,Description="Mutation not supported by data">
		##INFO=<ID=KMERSIZE,Number=1,Type=Integer,Description="K-mer size used to assemble the locus">
		##INFO=<ID=SB,Number=1,Type=Float,Description="Strand bias score: phred-scaled p-value of the Fisher's exact test for the forward/reverse read counts in the tumor">
		##INFO=<ID=MS,Number=1,Type=String,Description="Microsatellite mutation (format: #LEN#MOTIF)">
		##INFO=<ID=LEN,Number=1,Type=Integer,Description="Variant size in base pairs">
		##INFO=<ID=TYPE,Number=1,Type=String,Description="Variant type (snv, del, ins, complex)">
		##FILTER=<ID=LowCovNormal,Description="Low coverage in the normal (<10)">
		##FILTER=<ID=HighCovNormal,Description="High coverage in the normal (>1000000)">
		##FILTER=<ID=LowCovTumor,Description="Low coverage in the tumor (<4)">
		##FILTER=<ID=HighCovTumor,Description="High coverage in the tumor (>1000000)">
		##FILTER=<ID=LowVafTumor,Description="Low variant allele frequency in the tumor (<0.04)">
		##FILTER=<ID=HighVafNormal,Description="High variant allele frequency in the normal (>0)">
		##FILTER=<ID=LowAltCntTumor,Description="Low alternative allele count in the tumor (<3)">
		##FILTER=<ID=HighAltCntNormal,Description="High alternative allele count in the normal (>0)">
		##FILTER=<ID=LowFisherScore,Description="Low Fisher's exact test score for tumor-normal allele counts (<5)">
		##FILTER=<ID=LowFisherSTR,Description="Low Fisher's exact test score for tumor-normal STR allele counts (<25)">
		##FILTER=<ID=StrandBias,Description="Strand bias: # of non-reference reads in either forward or reverse strand below threshold (<1)">
		##FILTER=<ID=STR,Description="Microsatellite mutation">
		##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
		##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">
		##FORMAT=<ID=AD,Number=.,Type=Integer,Description="Allele depth: # of supporting ref,alt reads at the site">
		##FORMAT=<ID=SR,Number=.,Type=Integer,Description="Strand counts for ref: # of supporting forward,reverse reads for reference allele">
		##FORMAT=<ID=SA,Number=.,Type=Integer,Description="Strand counts for alt: # of supporting forward,reverse reads for alterantive allele">
		#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	
		END
fi

(${stage} ${picardMod}
		java -jar $EBROOTPICARD/picard.jar SortVcf \
			SD=/data/umcg-mterpstra/apps/data/ftp.broadinstitute.org/bundle/bundle17jan2020/hg38/Homo_sapiens_assembly38.fasta.dict \
			I=${lancetScatVcf}.tmp.vcf \
			O=${lancetScatVcf})
#java -Xmx8g -Djava.io.tmpdir=${mutect2Dir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
# -T MuTect2 \
# -R ${onekgGenomeFasta} \
# --dbsnp ${dbsnpVcf} \
# --cosmic ${cosmicVcf} \
# -I:tumor ${indelRealignmentBam} \
# $Normalspec \
# $InterValOperand \
# -o ${mutect2ScatVcf}.tmp.vcf#

#cleans name of any not [a-zA-Z0-9_]. It is up to the human interpreter to interpret these names, if needed.

#sampleNameClean=$(echo "${sampleName}" | perl -wpe 'chomp;$_=uc;s/\W/_/g;')

#this should be better than callerise is this case
#perl $EBROOTPIPELINEMINUTIL/bin/MutectAnnotationsToSampleFormat.pl TLOD,NLOD,MIN_ED,MAX_ED,ECNT,HCNT ${mutect2ScatVcf}.tmp.vcf  > ${mutect2ScatVcf}

#NORMAL="$(perl -wne 'if(s/.*NORMAL,SampleName=(.*?),.*/$1/){print};' ${mutect2ScatVcf}.tmp.vcf)"
#TUMOR="$(perl -wne 'if(s/.*TUMOR,SampleName=(.*?),.*/$1/){print};' ${mutect2ScatVcf}.tmp.vcf)"
#perl -i.tumornormal.bak -wpe 's/\tNORMAL/\t'"$NORMAL"'/;s/\tTUMOR/\t'"$TUMOR"'/;' ${mutect2ScatVcf}


#java -Xmx8g -Djava.io.tmpdir=${haplotyperDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
# -T HaplotypeCaller \
# -R ${onekgGenomeFasta} \
# --dbsnp ${dbsnpVcf}\
# $inputs \
# -stand_call_conf 10.0 \
# -o ${haplotyperScatVcf} \
# $InterValOperand \
# ${gatkOpt}


#java -jar GenomeAnalysisTK.jar \
#     -T MuTect2 \
#     -R reference.fasta \
#     -I:tumor tumor.bam \
#     -I:normal normal.bam \
#     [--dbsnp dbSNP.vcf] \
#     [--cosmic COSMIC.vcf] \
#     [-L targets.interval_list] \
#     -o output.vcf
# -I:eval ${indelRealignmentBam} \
# -I:genotype ${controlSampleBam} \
# --popfile ${popStratifiedVcf} \
# -L ${popStratifiedVcf} \
# -L ${targetsList} \
# -isr INTERSECTION \
# -o ${contEstLog}

#cp -v ${indelRealignmentBai} ${indelRealignmentBam}.bai

putFile ${lancetScatVcf}


echo "## "$(date)" ##  $0 Done "
