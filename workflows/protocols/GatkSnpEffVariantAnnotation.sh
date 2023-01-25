#MOLGENIS walltime=33:59:00 mem=9gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string gatkMod
#string gatkOpt
#string picardMod
#string dbsnpVcf
#string dbsnpVcfIdx
#string onekgGenomeFasta
#string onekgGenomeFastaDict
#list bqsrBam,bqsrBai
#string bqsrDir
#string targetsList

#string haplotyperDir
#string haplotyperVcf
#string haplotyperVcfIdx


#string annotatorDir
#string snpEffMod
#string vcfToolsMod
#string pipelineUtilMod
#string openCravatMod
#string snpEffStats
#string snpeffDataDir

#string snpEffGatkAnnotVcf
#string snpEffGatkAnnotVcfIdx
#string gatkAnnotVcf
#string gatkAnnotVcfIdx
#string snpEffAnnotVcf
#string snpEffAnnotVcfIdx

#string annotVcf
#string annotVcfIdx
#string cosmicVcf
#string cosmicVcfIdx
#string gnomadVcf
#string clinvarVcf
#string clinvarPapuVcf
#
#
#string oneKgPhase1SnpsVcf
#string oneKgPhase1SnpsVcfIdx


#snpEff stuff
#string motifBin
#string nextProtBin
#string pwmsBin
#string snpEffectPredictorBin


#string dbnsfp
#string dbnsfpTbi

alloutputsexist \
"${annotVcf}"

#"${annotVcfIdx}"

echo "## "$(date)" ##  $0 Started "

#string snpEffGatkAnnotVcf
#string snpEffGatkAnnotVcfIdx
#string gatkAnnotVcf
#string gatkAnnotVcfIdx
#string snpEffAnnotVcf
#string snpEffAnnotVcfIdx

#tired of typing getfile....
for file in "${gnomadVcf}" \
 "${clinvarVcf}" \
 "${clinvarPapuVcf}" \
 "${dbnsfp}" \
 "${dbnsfpTbi}" \
 "${oneKgPhase1SnpsVcf}" \
 "${oneKgPhase1SnpsVcfIdx}" \
 "${bqsrBam[@]}" \
 "${bqsrBai[@]}" \
 "${dbsnpVcf}" \
 "${dbsnpVcfIdx}" \
 "${onekgGenomeFasta}" \
 "${haplotyperVcf}" \
 "${cosmicVcf}" \
 "${cosmicVcfIdx}" \
 "${snpEffectPredictorBin}" 
do
	echo "getFile file='$file'"
	getFile $file
done

#Load snpeff/gatk module
${stage} ${snpEffMod}
${stage} ${gatkMod}
${stage} ${vcfToolsMod}
${stage} ${pipelineUtilMod}
${checkStage}

set -x
set -e

# sort unique and print like '-I file1.bam -I file2.bam '
bams=($(printf '%s\n' "$bqsrDir/*.bam" | sort -u ))
inputs=$(printf ' -I %s ' $(printf '%s\n' ${bams[@]}))

mkdir -p ${annotatorDir}

#pseudo: java -Xmx4g -jar $SnpEffJar \
#		 -c $SnpEffConfig \
#		 -v -o gatk \
#		 GRCh37.74 \
#		 $UGvcf \
#		1>$SnpEffvcf \
#		2>$MainDir/$LogDir/$PatientBase.$Prog.err.log \
#java -Xmx4g -jar $GatkJar \
#		 -T VariantAnnotator \
#		 -R $refFile \
#		 -D $dbSnpVcf \
#		 --filter_bases_not_stored \
#		 --useAllAnnotations \
#		 --excludeAnnotation MVLikelihoodRatio \
#		 --excludeAnnotation TechnologyComposition \
#		 --excludeAnnotation DepthPerSampleHC \
#		 --excludeAnnotation PercentNBaseSolid \
#		 --excludeAnnotation StrandBiasBySample \
#		 --snpEffFile $SnpEffvcf \
#		 --resource:cosmic,vcf $cosmicVcf \
#		 -E 'cosmic.ID' \
#		 --resource:1000g,vcf $oneKgP1wgsVcf \
#		 -E '1000g.AF' \
#		 -E '1000g.AFR_AF' \
#		 -E '1000g.AMR_AF' \
#		 -E '1000g.ASN_AF' \
#		 -E '1000g.EUR_AF' \
#		 --resource:dbSnp,vcf $dbSnpVcf \
#		 -E 'dbSnp.ASP' \
#		 -E 'dbSnp.ASS' \
#		.... \
#		 -E 'dbSnp.WTD' \
#		 -E 'dbSnp.dbSNPBuildID' \
#		 -V $UGvcf \
#		 -o $Annotvcf \
#		  $ { unifiedGenotyperInputBams[*] } \
#		 -L $UGvcf \
#		1>$Check \
#		2>$MainDir/$LogDir/$PatientBase.$Prog.err.log 



java -Xmx8g -jar  $EBROOTSNPEFF/snpEff.jar \
 -c $EBROOTSNPEFF/snpEff.config \
 -dataDir ${snpeffDataDir} \
 -stats ${snpEffStats} \
 -csvStats ${snpEffStats}.csv \
 -v -o gatk \
 GRCh38.86 \
 ${haplotyperVcf} \
 1>${snpEffGatkAnnotVcf}
 
rm -v ${snpEffStats}  ${snpEffStats}.csv \

>&2 echo -e $(date)" ## INFO ## SnpEff for GATK done "


#review  --excludeAnnotation MVLikelihoodRatio 

java -Xmx8g -Djava.io.tmpdir=${annotatorDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T VariantAnnotator \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf} \
 ${inputs[@]} \
 --snpEffFile ${snpEffGatkAnnotVcf} \
 --resource:cosmic,VCF ${cosmicVcf} \
 -E 'cosmic.ID' \
 --resource:dbSnp,vcf ${dbsnpVcf} \
 -E 'dbSnp.CAF' \
 -E 'dbSnp.COMMON' \
 -E 'dbSnp.dbSNPBuildID' \
 -V:input,VCF ${haplotyperVcf} \
 --out ${gatkAnnotVcf} \
 -L ${haplotyperVcf} \
 ${gatkOpt}

>&2 echo -e $(date)" ## INFO ## GATK VariantAnnotator  done "


java -Xmx8g -jar  $EBROOTSNPEFF/snpEff.jar \
 -c $EBROOTSNPEFF/snpEff.config \
 -dataDir ${snpeffDataDir} \
 -formatEff \
 -canon \
 -hgvs \
 -stats ${snpEffStats} \
 -csvStats ${snpEffStats}.csv \
 -v \
 GRCh38.86 \
 ${gatkAnnotVcf} \
 1>${snpEffAnnotVcf}.tmp.vcf

rm  -v ${snpEffStats} ${snpEffStats}.csv \

>&2 echo -e $(date)" ## INFO ## SnpEff eff fields done "


java -Xmx8g -jar  $EBROOTSNPEFF/snpEff.jar \
 -c $EBROOTSNPEFF/snpEff.config \
 -dataDir ${snpeffDataDir} \
 -hgvs \
 -lof \
 -canon \
 -stats ${snpEffStats} \
 -csvStats ${snpEffStats}.csv \
 -v \
 GRCh38.86 \
 ${gatkAnnotVcf} | \
perl $EBROOTPIPELINEMINUTIL/bin/VcfSnpEffAsGatk.pl \
  /dev/stdin \
  1>${snpEffAnnotVcf}

>&2 echo -e $(date)" ## INFO ## SnpEff ANN plus VcfSnpEffAsGatk done "


#dont mind the multiline 
java -Xmx8g -jar $EBROOTSNPEFF/SnpSift.jar \
 dbnsfp -db ${dbnsfp} \
 -f 'chr,pos(1-based),ref,alt,aaref,aaalt,rs_dbSNP151,hg19_chr,hg19_pos(1-based),hg18_chr,hg18_pos(1-based),aapos,genename,Ensembl_geneid,Ensembl_transcriptid,Ensembl_proteinid,Uniprot_acc,Uniprot_entry,HGVSc_ANNOVAR,HGVSp_ANNOVAR,HGVSc_snpEff,HGVSp_snpEff,HGVSc_VEP,HGVSp_VEP,APPRIS,GENCODE_basic,TSL,VEP_canonical,cds_strand,refcodon,codonpos,codon_degeneracy,Ancestral_allele,AltaiNeandertal,Denisova,VindijiaNeandertal,SIFT_score,SIFT_converted_rankscore,SIFT_pred,SIFT4G_score,SIFT4G_converted_rankscore,SIFT4G_pred,Polyphen2_HDIV_score,Polyphen2_HDIV_rankscore,Polyphen2_HDIV_pred,Polyphen2_HVAR_score,Polyphen2_HVAR_rankscore,Polyphen2_HVAR_pred,LRT_score,LRT_converted_rankscore,LRT_pred,LRT_Omega,MutationTaster_score,MutationTaster_converted_rankscore,MutationTaster_pred,MutationTaster_model,MutationTaster_AAE,MutationAssessor_score,MutationAssessor_rankscore,MutationAssessor_pred,FATHMM_score,FATHMM_converted_rankscore,FATHMM_pred,PROVEAN_score,PROVEAN_converted_rankscore,PROVEAN_pred,VEST4_score,VEST4_rankscore,MetaSVM_score,MetaSVM_rankscore,MetaSVM_pred,MetaLR_score,MetaLR_rankscore,MetaLR_pred,Reliability_index,M-CAP_score,M-CAP_rankscore,M-CAP_pred,REVEL_score,REVEL_rankscore,MutPred_score,MutPred_rankscore,MutPred_protID,MutPred_AAchange,MutPred_Top5features,MVP_score,MVP_rankscore,MPC_score,MPC_rankscore,PrimateAI_score,PrimateAI_rankscore,PrimateAI_pred,DEOGEN2_score,DEOGEN2_rankscore,DEOGEN2_pred,Aloft_Fraction_transcripts_affected,Aloft_prob_Tolerant,Aloft_prob_Recessive,Aloft_prob_Dominant,Aloft_pred,Aloft_Confidence,CADD_raw,CADD_raw_rankscore,CADD_phred,DANN_score,DANN_rankscore,fathmm-MKL_coding_score,fathmm-MKL_coding_rankscore,fathmm-MKL_coding_pred,fathmm-MKL_coding_group,fathmm-XF_coding_score,fathmm-XF_coding_rankscore,fathmm-XF_coding_pred,Eigen-raw_coding,Eigen-raw_coding_rankscore,Eigen-pred_coding,Eigen-PC-raw_coding,Eigen-PC-raw_coding_rankscore,Eigen-PC-phred_coding,GenoCanyon_score,GenoCanyon_rankscore,integrated_fitCons_score,integrated_fitCons_rankscore,integrated_confidence_value,GM12878_fitCons_score,GM12878_fitCons_rankscore,GM12878_confidence_value,H1-hESC_fitCons_score,H1-hESC_fitCons_rankscore,H1-hESC_confidence_value,HUVEC_fitCons_score,HUVEC_fitCons_rankscore,HUVEC_confidence_value,LINSIGHT,LINSIGHT_rankscore,GERP++_NR,GERP++_RS,GERP++_RS_rankscore,phyloP100way_vertebrate,phyloP100way_vertebrate_rankscore,phyloP30way_mammalian,phyloP30way_mammalian_rankscore,phyloP17way_primate,phyloP17way_primate_rankscore,phastCons100way_vertebrate,phastCons100way_vertebrate_rankscore,phastCons30way_mammalian,phastCons30way_mammalian_rankscore,phastCons17way_primate,phastCons17way_primate_rankscore,SiPhy_29way_pi,SiPhy_29way_logOdds,SiPhy_29way_logOdds_rankscore,bStatistic,bStatistic_rankscore,1000Gp3_AC,1000Gp3_AF,1000Gp3_AFR_AC,1000Gp3_AFR_AF,1000Gp3_EUR_AC,1000Gp3_EUR_AF,1000Gp3_AMR_AC,1000Gp3_AMR_AF,1000Gp3_EAS_AC,1000Gp3_EAS_AF,1000Gp3_SAS_AC,1000Gp3_SAS_AF,TWINSUK_AC,TWINSUK_AF,ALSPAC_AC,ALSPAC_AF,UK10K_AC,UK10K_AF,ESP6500_AA_AC,ESP6500_AA_AF,ESP6500_EA_AC,ESP6500_EA_AF,ExAC_AC,ExAC_AF,ExAC_Adj_AC,ExAC_Adj_AF,ExAC_AFR_AC,ExAC_AFR_AF,ExAC_AMR_AC,ExAC_AMR_AF,ExAC_EAS_AC,ExAC_EAS_AF,ExAC_FIN_AC,ExAC_FIN_AF,ExAC_NFE_AC,ExAC_NFE_AF,ExAC_SAS_AC,ExAC_SAS_AF,ExAC_nonTCGA_AC,ExAC_nonTCGA_AF,ExAC_nonTCGA_Adj_AC,ExAC_nonTCGA_Adj_AF,ExAC_nonTCGA_AFR_AC,ExAC_nonTCGA_AFR_AF,ExAC_nonTCGA_AMR_AC,ExAC_nonTCGA_AMR_AF,ExAC_nonTCGA_EAS_AC,ExAC_nonTCGA_EAS_AF,ExAC_nonTCGA_FIN_AC,ExAC_nonTCGA_FIN_AF,ExAC_nonTCGA_NFE_AC,ExAC_nonTCGA_NFE_AF,ExAC_nonTCGA_SAS_AC,ExAC_nonTCGA_SAS_AF,ExAC_nonpsych_AC,ExAC_nonpsych_AF,ExAC_nonpsych_Adj_AC,ExAC_nonpsych_Adj_AF,ExAC_nonpsych_AFR_AC,ExAC_nonpsych_AFR_AF,ExAC_nonpsych_AMR_AC,ExAC_nonpsych_AMR_AF,ExAC_nonpsych_EAS_AC,ExAC_nonpsych_EAS_AF,ExAC_nonpsych_FIN_AC,ExAC_nonpsych_FIN_AF,ExAC_nonpsych_NFE_AC,ExAC_nonpsych_NFE_AF,ExAC_nonpsych_SAS_AC,ExAC_nonpsych_SAS_AF,gnomAD_exomes_flag,gnomAD_exomes_AC,gnomAD_exomes_AN,gnomAD_exomes_AF,gnomAD_exomes_nhomalt,gnomAD_exomes_AFR_AC,gnomAD_exomes_AFR_AN,gnomAD_exomes_AFR_AF,gnomAD_exomes_AFR_nhomalt,gnomAD_exomes_AMR_AC,gnomAD_exomes_AMR_AN,gnomAD_exomes_AMR_AF,gnomAD_exomes_AMR_nhomalt,gnomAD_exomes_ASJ_AC,gnomAD_exomes_ASJ_AN,gnomAD_exomes_ASJ_AF,gnomAD_exomes_ASJ_nhomalt,gnomAD_exomes_EAS_AC,gnomAD_exomes_EAS_AN,gnomAD_exomes_EAS_AF,gnomAD_exomes_EAS_nhomalt,gnomAD_exomes_FIN_AC,gnomAD_exomes_FIN_AN,gnomAD_exomes_FIN_AF,gnomAD_exomes_FIN_nhomalt,gnomAD_exomes_NFE_AC,gnomAD_exomes_NFE_AN,gnomAD_exomes_NFE_AF,gnomAD_exomes_NFE_nhomalt,gnomAD_exomes_SAS_AC,gnomAD_exomes_SAS_AN,gnomAD_exomes_SAS_AF,gnomAD_exomes_SAS_nhomalt,gnomAD_exomes_POPMAX_AC,gnomAD_exomes_POPMAX_AN,gnomAD_exomes_POPMAX_AF,gnomAD_exomes_POPMAX_nhomalt,gnomAD_exomes_controls_AC,gnomAD_exomes_controls_AN,gnomAD_exomes_controls_AF,gnomAD_exomes_controls_nhomalt,gnomAD_exomes_controls_AFR_AC,gnomAD_exomes_controls_AFR_AN,gnomAD_exomes_controls_AFR_AF,gnomAD_exomes_controls_AFR_nhomalt,gnomAD_exomes_controls_AMR_AC,gnomAD_exomes_controls_AMR_AN,gnomAD_exomes_controls_AMR_AF,gnomAD_exomes_controls_AMR_nhomalt,gnomAD_exomes_controls_ASJ_AC,gnomAD_exomes_controls_ASJ_AN,gnomAD_exomes_controls_ASJ_AF,gnomAD_exomes_controls_ASJ_nhomalt,gnomAD_exomes_controls_EAS_AC,gnomAD_exomes_controls_EAS_AN,gnomAD_exomes_controls_EAS_AF,gnomAD_exomes_controls_EAS_nhomalt,gnomAD_exomes_controls_FIN_AC,gnomAD_exomes_controls_FIN_AN,gnomAD_exomes_controls_FIN_AF,gnomAD_exomes_controls_FIN_nhomalt,gnomAD_exomes_controls_NFE_AC,gnomAD_exomes_controls_NFE_AN,gnomAD_exomes_controls_NFE_AF,gnomAD_exomes_controls_NFE_nhomalt,gnomAD_exomes_controls_SAS_AC,gnomAD_exomes_controls_SAS_AN,gnomAD_exomes_controls_SAS_AF,gnomAD_exomes_controls_SAS_nhomalt,gnomAD_exomes_controls_POPMAX_AC,gnomAD_exomes_controls_POPMAX_AN,gnomAD_exomes_controls_POPMAX_AF,gnomAD_exomes_controls_POPMAX_nhomalt,gnomAD_genomes_flag,gnomAD_genomes_AC,gnomAD_genomes_AN,gnomAD_genomes_AF,gnomAD_genomes_nhomalt,gnomAD_genomes_AFR_AC,gnomAD_genomes_AFR_AN,gnomAD_genomes_AFR_AF,gnomAD_genomes_AFR_nhomalt,gnomAD_genomes_AMR_AC,gnomAD_genomes_AMR_AN,gnomAD_genomes_AMR_AF,gnomAD_genomes_AMR_nhomalt,gnomAD_genomes_ASJ_AC,gnomAD_genomes_ASJ_AN,gnomAD_genomes_ASJ_AF,gnomAD_genomes_ASJ_nhomalt,gnomAD_genomes_EAS_AC,gnomAD_genomes_EAS_AN,gnomAD_genomes_EAS_AF,gnomAD_genomes_EAS_nhomalt,gnomAD_genomes_FIN_AC,gnomAD_genomes_FIN_AN,gnomAD_genomes_FIN_AF,gnomAD_genomes_FIN_nhomalt,gnomAD_genomes_NFE_AC,gnomAD_genomes_NFE_AN,gnomAD_genomes_NFE_AF,gnomAD_genomes_NFE_nhomalt,gnomAD_genomes_POPMAX_AC,gnomAD_genomes_POPMAX_AN,gnomAD_genomes_POPMAX_AF,gnomAD_genomes_POPMAX_nhomalt,gnomAD_genomes_controls_AC,gnomAD_genomes_controls_AN,gnomAD_genomes_controls_AF,gnomAD_genomes_controls_nhomalt,gnomAD_genomes_controls_AFR_AC,gnomAD_genomes_controls_AFR_AN,gnomAD_genomes_controls_AFR_AF,gnomAD_genomes_controls_AFR_nhomalt,gnomAD_genomes_controls_AMR_AC,gnomAD_genomes_controls_AMR_AN,gnomAD_genomes_controls_AMR_AF,gnomAD_genomes_controls_AMR_nhomalt,gnomAD_genomes_controls_ASJ_AC,gnomAD_genomes_controls_ASJ_AN,gnomAD_genomes_controls_ASJ_AF,gnomAD_genomes_controls_ASJ_nhomalt,gnomAD_genomes_controls_EAS_AC,gnomAD_genomes_controls_EAS_AN,gnomAD_genomes_controls_EAS_AF,gnomAD_genomes_controls_EAS_nhomalt,gnomAD_genomes_controls_FIN_AC,gnomAD_genomes_controls_FIN_AN,gnomAD_genomes_controls_FIN_AF,gnomAD_genomes_controls_FIN_nhomalt,gnomAD_genomes_controls_NFE_AC,gnomAD_genomes_controls_NFE_AN,gnomAD_genomes_controls_NFE_AF,gnomAD_genomes_controls_NFE_nhomalt,gnomAD_genomes_controls_POPMAX_AC,gnomAD_genomes_controls_POPMAX_AN,gnomAD_genomes_controls_POPMAX_AF,gnomAD_genomes_controls_POPMAX_nhomalt,clinvar_id,clinvar_clnsig,clinvar_trait,clinvar_review,clinvar_hgvs,clinvar_var_source,clinvar_MedGen_id,clinvar_OMIM_id,clinvar_Orphanet_id,Interpro_domain,GTEx_V7_gene,GTEx_V7_tissue,Geuvadis_eQTL_target_gene' \
 ${snpEffAnnotVcf} \
 1>${annotVcf}.snpsiftdbnsfp.vcf \

>&2 echo -e $(date)" ## INFO ## SnpSift dbnsfp done "


#(
#	
#	${stage} ${openCravatMod}
#	
#	if [ -e ${annotVcf}.snpsiftdbnsfp.vcf.sqlite ]; then 
#		>&2 echo -e $(date)" ## INFO ## Cleaning up OpenCravat output"
#		rm -v ${annotVcf}.snpsiftdbnsfp.vcf.*
#	fi
#	mkdir -p ${annotatorDir}/oc/
#	oc run ${annotVcf}.snpsiftdbnsfp.vcf -d ${annotatorDir}/oc/ --mp 4 -l hg38 -t vcf
#	
#	#this thingy unsorts thecoordinates
#	#so
#)
#(
#	${stage} ${picardMod}
#	
#	java -Xmx12g -XX:ParallelGCThreads=2 -jar $EBROOTPICARD/picard.jar \
#	 SortVcf \
#	 INPUT=${annotVcf}.snpsiftdbnsfp.vcf.vcf \
#	 OUTPUT=${annotVcf}.oc.sorted.vcf \
#	 SD=${onekgGenomeFastaDict}
#	
#	>&2 echo -e $(date)" ## INFO ## Opencravat done "
#
#)

# java -jar SnpSift.jar annotate dbSnp132.vcf variants.vcf > variants_annotated.vcf 
java -Xmx8g -jar $EBROOTSNPEFF/SnpSift.jar annotate \
 ${gnomadVcf} \
 ${annotVcf}.snpsiftdbnsfp.vcf > ${annotVcf}.snpsiftannot.vcf

#${annotVcf}.oc.sorted.vcf > ${annotVcf}.snpsiftannot.vcf

>&2 echo -e $(date)" ## INFO ## SnpSift gnomad done "

#sorted gzipped bedfile 
grep -v '^@' ${targetsList} |\
 perl -wlane 'print join("\t",($F[0],$F[1]-1,$F[2],$.));' |\
 sort -k1,1V -k2,3n| bgzip >  ${annotVcf}.targets.bed.gz
#of course with tabix index
tabix -p bed ${annotVcf}.targets.bed.gz

#new format
#vcf-annotate -a test.bed.gz -c CHROM,FROM,TO,INTARGETREGION -h hdr.file in.vcf

#old .12 format
vcf-annotate \
 -d key=INFO,ID=INTARGETREGION,Number=0,Type=Flag,Description='In target region specified by capturing kit target intervals.' \
 -c CHROM,FROM,TO,INFO/INTARGETREGION \
 -a ${annotVcf}.targets.bed.gz \
 ${annotVcf}.snpsiftannot.vcf \
 >${annotVcf}

>&2 echo -e $(date)" ## INFO ## vcftools vcf-annotate done "

rm -v ${snpEffAnnotVcf}* ${gatkAnnotVcf}* ${snpEffGatkAnnotVcf}* 

# maybe nececary
# -U LENIENT_VCF_PROCESSING
# -U ALLOW_N_CIGAR_READS

putFile ${annotVcf}
#putFile ${annotVcfIdx}

echo "## "$(date)" ##  $0 Done "
