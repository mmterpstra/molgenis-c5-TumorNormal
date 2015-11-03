#MOLGENIS walltime=23:59:00 mem=8gb ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string gatkMod
#string dbsnpVcf
#string dbsnpVcfIdx
#string onekgGenomeFasta
#list bqsrBam,bqsrBai

#string haplotyperDir
#string haplotyperVcf
#string haplotyperVcfIdx


#string annotatorDir
#string snpEffMod
#string snpEffStats

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
#string exacVcf
#string exacVcfIdx
#string oneKgPhase1SnpsVcf
#string oneKgPhase1SnpsVcfIdx
#string oneKgPhase1IndelsVcf
#string oneKgPhase1IndelsVcfIdx


#snpEff stuff
#string motifBin
#string nextProtBin
#string pwmsBin
#string regulation_CD4Bin
#string regulation_GM06990Bin
#string regulation_GM12878Bin
#string regulation_H1ESCBin
#string regulation_HeLaS3Bin
#string regulation_HepG2Bin
#string regulation_HMECBin
#string regulation_HSMMBin
#string regulation_HUVECBin
#string regulation_IMR90Bin
#string regulation_K562bBin
#string regulation_K562Bin
#string regulation_NHABin
#string regulation_NHEKBin
#string snpEffectPredictorBin

#string oneKgP1wgsVcf
#string oneKgP1wgsVcfIdx

#string dbnsfp
#string dbnsfpTbi

alloutputsexist \
"${annotVcf}" \
"${annotVcfIdx}"

echo "## "$(date)" ##  $0 Started "

#string snpEffGatkAnnotVcf
#string snpEffGatkAnnotVcfIdx
#string gatkAnnotVcf
#string gatkAnnotVcfIdx
#string snpEffAnnotVcf
#string snpEffAnnotVcfIdx

#tired of typing getfile....
for file in "${oneKgP1wgsVcf}" "${oneKgP1wgsVcfIdx}" "${exacVcf}" "${exacVcfIdx}" "${dbnsfp}" "${dbnsfpTbi}" "${oneKgPhase1SnpsVcf}" "${oneKgPhase1SnpsVcfIdx}" "${oneKgPhase1IndelsVcf}" "${oneKgPhase1IndelsVcfIdx}" "${bqsrBam[@]}" "${bqsrBai[@]}" "${dbsnpVcf}" "${dbsnpVcfIdx}" "${onekgGenomeFasta}" "${haplotyperVcf}" "${haplotyperVcfIdx}" "${cosmicVcf}" "${cosmicVcfIdx}" "${regulation_CD4Bin}"  "${regulation_GM06990Bin}"  "${regulation_GM12878Bin}"  "${regulation_H1ESCBin}"  "${regulation_HeLaS3Bin}"  "${regulation_HepG2Bin}"  "${regulation_HMECBin}"  "${regulation_HSMMBin}"  "${regulation_HUVECBin}"  "${regulation_IMR90Bin}"  "${regulation_K562bBin}"  "${regulation_K562Bin}"  "${regulation_NHABin}"  "${regulation_NHEKBin}"  "${snpEffectPredictorBin}" ; do
	echo "getFile file='$file'"
	getFile $file
done

#Load snpeff/gatk module
${stage} ${snpEffMod}
${stage} ${gatkMod}
${checkStage}

set -x
set -e

# sort unique and print like '-I file1.bam -I file2.bam '
bams=($(printf '%s\n' "${bqsrBam[@]}" | sort -u ))
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
 -stats ${snpEffStats} \
 -v -o gatk \
 GRCh37.75 \
 ${haplotyperVcf} \
 1>${snpEffGatkAnnotVcf}
 
rm -v ${snpEffStats}


#review  --excludeAnnotation MVLikelihoodRatio 

java -Xmx8g -Djava.io.tmpdir=${annotatorDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T VariantAnnotator \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf} \
 ${inputs[@]} \
 --excludeAnnotation MVLikelihoodRatio \
 --excludeAnnotation TechnologyComposition \
 --excludeAnnotation DepthPerSampleHC \
 --excludeAnnotation PercentNBaseSolid \
 --excludeAnnotation PossibleDeNovo \
 --filter_bases_not_stored \
 --useAllAnnotations \
 --snpEffFile ${snpEffGatkAnnotVcf} \
 --resource:cosmic,VCF ${cosmicVcf} \
 -E 'cosmic.ID' \
  --resource:1000gPhase1Snps,vcf ${oneKgP1wgsVcf} \
 -E '1000gPhase1Snps.AF' \
 -E '1000gPhase1Snps.AFR_AF' \
 -E '1000gPhase1Snps.AMR_AF' \
 -E '1000gPhase1Snps.ASN_AF' \
 -E '1000gPhase1Snps.EUR_AF' \
  --resource:1000gPhase1Indels,vcf ${oneKgPhase1IndelsVcf} \
 -E '1000gPhase1Indels.AF' \
 -E '1000gPhase1Indels.AFR_AF' \
 -E '1000gPhase1Indels.AMR_AF' \
 -E '1000gPhase1Indels.ASN_AF' \
 -E '1000gPhase1Indels.EUR_AF' \
 --resource:dbSnp,vcf ${dbsnpVcf} \
 -E 'dbSnp.CAF' \
 -E 'dbSnp.COMMON' \
 -E 'dbSnp.dbSNPBuildID' \
 --resource:exac,vcf ${exacVcf} \
 -E 'exac.AC' \
 -E 'exac.AN' \
 -E 'exac.AC_Adj' \
 -E 'exac.AC_Hom' \
 -E 'exac.AC_Het' \
 -E 'exac.AC_Hemi' \
 -E 'exac.AN_AFR' \
 -E 'exac.AC_AFR' \
 -E 'exac.AC_AMR' \
 -E 'exac.AN_AMR' \
 -E 'exac.AC_EAS' \
 -E 'exac.AN_EAS' \
 -E 'exac.AC_FIN' \
 -E 'exac.AN_FIN' \
 -E 'exac.AC_OTH' \
 -E 'exac.AN_OTH' \
 -E 'exac.AN_SAS' \
 -E 'exac.AC_SAS' \
 -V:input,VCF ${haplotyperVcf} \
 --out ${gatkAnnotVcf} \
 -L ${haplotyperVcf} \
 
java -Xmx8g -jar  $EBROOTSNPEFF/snpEff.jar \
 -c $EBROOTSNPEFF/snpEff.config \
 -formatEff \
 -canon \
 -hgvs \
 -stats ${snpEffStats} \
 -v \
 GRCh37.75 \
 ${gatkAnnotVcf} \
 1>${snpEffAnnotVcf}.tmp.vcf
 
rm  -v ${snpEffStats}

java -Xmx8g -jar  $EBROOTSNPEFF/snpEff.jar \
 -c $EBROOTSNPEFF/snpEff.config \
 -hgvs \
 -lof \
 -stats ${snpEffStats} \
 -v \
 GRCh37.75 \
 ${snpEffAnnotVcf}.tmp.vcf \
 1>${snpEffAnnotVcf}.anneff.vcf
 
rm  -v ${snpEffStats}

java -Xmx8g -jar  $EBROOTSNPEFF/snpEff.jar \
 -c $EBROOTSNPEFF/snpEff.config \
 -hgvs \
 -lof \
 -stats ${snpEffStats} \
 -v \
 GRCh37.75 \
 ${gatkAnnotVcf} \
 1>${snpEffAnnotVcf}
 
java -Xmx8g -jar $EBROOTSNPEFF/SnpSift.jar \
 dbnsfp -db ${dbnsfp}\
 -f genename,Uniprot_acc,Uniprot_id,Uniprot_aapos,Interpro_domain,cds_strand,refcodon,SLR_test_statistic,codonpos,fold-degenerate,Ancestral_allele,Ensembl_geneid,Ensembl_transcriptid,aapos,aapos_SIFT,aapos_FATHMM,SIFT_score,SIFT_converted_rankscore,SIFT_pred,Polyphen2_HDIV_score,Polyphen2_HDIV_rankscore,Polyphen2_HDIV_pred,Polyphen2_HVAR_score,Polyphen2_HVAR_rankscore,Polyphen2_HVAR_pred,LRT_score,LRT_converted_rankscore,LRT_pred,MutationTaster_score,MutationTaster_converted_rankscore,MutationTaster_pred,MutationAssessor_score,MutationAssessor_rankscore,MutationAssessor_pred,FATHMM_score,FATHMM_rankscore,FATHMM_pred,RadialSVM_score,RadialSVM_rankscore,RadialSVM_pred,LR_score,LR_rankscore,LR_pred,Reliability_index,VEST3_score,VEST3_rankscore,CADD_raw,CADD_raw_rankscore,CADD_phred,GERP++_NR,GERP++_RS,GERP++_RS_rankscore,phyloP46way_primate,phyloP46way_primate_rankscore,phyloP46way_placental,phyloP46way_placental_rankscore,phyloP100way_vertebrate,phyloP100way_vertebrate_rankscore,phastCons46way_primate,phastCons46way_primate_rankscore,phastCons46way_placental,phastCons46way_placental_rankscore,phastCons100way_vertebrate,phastCons100way_vertebrate_rankscore,SiPhy_29way_pi,SiPhy_29way_logOdds,SiPhy_29way_logOdds_rankscore,LRT_Omega,UniSNP_ids,1000Gp1_AC,1000Gp1_AF,1000Gp1_AFR_AC,1000Gp1_AFR_AF,1000Gp1_EUR_AC,1000Gp1_EUR_AF,1000Gp1_AMR_AC,1000Gp1_AMR_AF,1000Gp1_ASN_AC,1000Gp1_ASN_AF,ESP6500_AA_AF,ESP6500_EA_AF,ARIC5606_AA_AC,ARIC5606_AA_AF,ARIC5606_EA_AC,ARIC5606_EA_AF,clinvar_rs,clinvar_clnsig,clinvar_trait \
 ${snpEffAnnotVcf} \
 1>${annotVcf} \
 

rm -v ${snpEffAnnotVcf}* ${gatkAnnotVcf}* ${snpEffGatkAnnotVcf}* 

# maybe nececary
# -U LENIENT_VCF_PROCESSING
# -U ALLOW_N_CIGAR_READS

putFile ${annotVcf}
putFile ${annotVcfIdx}

echo "## "$(date)" ##  $0 Done "
