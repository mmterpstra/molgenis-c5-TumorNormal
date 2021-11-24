#MOLGENIS walltime=23:59:00 mem=2gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir
#string onekgGenomeFasta

#string vcf

#string tableDir
#string variantTable
#string variantRawTable
#string variantFields
#string gatkMod
#string vcfToolsMod
#string pipelineUtilMod


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${variantTable}"

for file in "${vcf}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} ${gatkMod}
${stage} ${vcfToolsMod}
${stage} ${pipelineUtilMod}
${checkStage}

set -x
set -e

mkdir -p ${tableDir}

if [ $(grep -vP '^#'  ${vcf}| wc -l) -ge 1 ]; then

	if [ ${#variantFields} -eq 0 ]; then
		#all fields minus the -GF FT from manta
		fields=$(perl $EBROOTPIPELINEMINUTIL/bin/DumpFieldsForVariantsToTable.pl ${vcf}| perl -wpe 's/\-GF\ FT//g' )
		#notice the intentional space to prevent ac_afr_male be partially removed by ac_afr
		fieldsclean=$(echo $fields| perl -wpe 's/-F (AC_afr_female|AC_afr_male|AC_ami_female|AC_ami_male|AC_amr_female|AC_amr_male|AC_asj_female|AC_asj_male|AC_eas_female|AC_eas_male|AC_fin_female|AC_fin_male|AC_nfe_female|AC_nfe_male|AC_oth_female|AC_oth_male|AC_sas_female|AC_sas_male|AF_afr_female|AF_afr_male|AF_ami_female|AF_ami_male|AF_amr_female|AF_amr_male|AF_asj_female|AF_asj_male|AF_eas_female|AF_eas_male|AF_fin_female|AF_fin_male|AF_nfe_female|AF_nfe_male|AF_oth_female|AF_oth_male|AF_sas_female|AF_sas_male|AN_afr_female|AN_afr_male|AN_ami_female|AN_ami_male|AN_amr_female|AN_amr_male|AN_asj_female|AN_asj_male|AN_eas_female|AN_eas_male|AN_fin_female|AN_fin_male|AN_nfe_female|AN_nfe_male|AN_oth_female|AN_oth_male|AN_sas_female|AN_sas_male|FreebayesAB|FreebayesABP|FreebayesAC|FreebayesAF|FreebayesAN|FreebayesAO|FreebayesCIGAR|FreebayesDP|FreebayesDPB|FreebayesDPRA|FreebayesEND|FreebayesEPP|FreebayesEPPR|FreebayesGTI|FreebayesLEN|FreebayesMEANALT|FreebayesMIN_DP|FreebayesMQM|FreebayesMQMR|FreebayesNS|FreebayesNUMALT|FreebayesODDS|FreebayesPAIRED|FreebayesPAIREDR|FreebayesPAO|FreebayesPQA|FreebayesPQR|FreebayesPRO|FreebayesQA|FreebayesQR|FreebayesRO|FreebayesRPL|FreebayesRPP|FreebayesRPPR|FreebayesRPR|FreebayesRUN|FreebayesSAF|FreebayesSAP|FreebayesSAR|FreebayesSRF|FreebayesSRP|FreebayesSRR|FreebayesTYPE|Freebayestechnology.illumina|HCallerAC|HCallerAF|HCallerAN|HCallerASP|HCallerASS|HCallerBaseQRankSum|HCallerCAF|HCallerCDA|HCallerCFL|HCallerCOMMON|HCallerClippingRankSum|HCallerDB|HCallerDP|HCallerDS|HCallerDSS|HCallerEND|HCallerExcessHet|HCallerFS|HCallerG5|HCallerG5A|HCallerGENEINFO|HCallerGNO|HCallerHD|HCallerHaplotypeScore|HCallerINT|HCallerInbreedingCoeff|HCallerKGPhase1|HCallerKGPhase3|HCallerLSD|HCallerMLEAC|HCallerMLEAF|HCallerMQ|HCallerMQRankSum|HCallerMTP|HCallerMUT|HCallerNOC|HCallerNOV|HCallerNSF|HCallerNSM|HCallerNSN|HCallerOM|HCallerOTH|HCallerPM|HCallerPMC|HCallerQD|HCallerR3|HCallerR5|HCallerRAW_MQ|HCallerREF|HCallerRS|HCallerRSPOS|HCallerRV|HCallerReadPosRankSum|HCallerS3D|HCallerSAO|HCallerSLO|HCallerSOR|HCallerSSR|HCallerSYN|HCallerTPA|HCallerU3|HCallerU5|HCallerVC|HCallerVLD|HCallerVP|HCallerWGT|HCallerWTD|HCallerdbSNPBuildID|MuTect2AC|MuTect2AF|MuTect2AN|MuTect2DB|MuTect2PON|NEGATIVE_TRAIN_SITE|POSITIVE_TRAIN_SITE|SNPEFF_AMINO_ACID_CHANGE|SNPEFF_CODON_CHANGE|SNPEFF_EFFECT|SNPEFF_EXON_ID|SNPEFF_FUNCTIONAL_CLASS|SNPEFF_GENE_BIOTYPE|SNPEFF_GENE_NAME|SNPEFF_IMPACT|SNPEFF_TRANSCRIPT_ID|dbNSFP_ExAC_nonpsych_AC|dbNSFP_ExAC_nonpsych_AF|dbNSFP_ExAC_nonpsych_AFR_AC|dbNSFP_ExAC_nonpsych_AFR_AF|dbNSFP_ExAC_nonpsych_AMR_AC|dbNSFP_ExAC_nonpsych_AMR_AF|dbNSFP_ExAC_nonpsych_Adj_AC|dbNSFP_ExAC_nonpsych_Adj_AF|dbNSFP_ExAC_nonpsych_EAS_AC|dbNSFP_ExAC_nonpsych_EAS_AF|dbNSFP_ExAC_nonpsych_FIN_AC|dbNSFP_ExAC_nonpsych_FIN_AF|dbNSFP_ExAC_nonpsych_NFE_AC|dbNSFP_ExAC_nonpsych_NFE_AF|dbNSFP_ExAC_nonpsych_SAS_AC|dbNSFP_ExAC_nonpsych_SAS_AF|dbNSFP_gnomAD_exomes_AF|dbNSFP_gnomAD_exomes_AFR_AF|dbNSFP_gnomAD_exomes_AFR_nhomalt|dbNSFP_gnomAD_exomes_AMR_AF|dbNSFP_gnomAD_exomes_AMR_nhomalt|dbNSFP_gnomAD_exomes_ASJ_AF|dbNSFP_gnomAD_exomes_ASJ_nhomalt|dbNSFP_gnomAD_exomes_EAS_AF|dbNSFP_gnomAD_exomes_EAS_nhomalt|dbNSFP_gnomAD_exomes_FIN_AF|dbNSFP_gnomAD_exomes_FIN_nhomalt|dbNSFP_gnomAD_exomes_NFE_AF|dbNSFP_gnomAD_exomes_NFE_nhomalt|dbNSFP_gnomAD_exomes_POPMAX_AF|dbNSFP_gnomAD_exomes_POPMAX_nhomalt|dbNSFP_gnomAD_exomes_SAS_AF|dbNSFP_gnomAD_exomes_SAS_nhomalt|dbNSFP_gnomAD_exomes_controls_AF|dbNSFP_gnomAD_exomes_controls_AFR_AF|dbNSFP_gnomAD_exomes_controls_AFR_nhomalt|dbNSFP_gnomAD_exomes_controls_AMR_AF|dbNSFP_gnomAD_exomes_controls_AMR_nhomalt|dbNSFP_gnomAD_exomes_controls_ASJ_AF|dbNSFP_gnomAD_exomes_controls_ASJ_nhomalt|dbNSFP_gnomAD_exomes_controls_EAS_AF|dbNSFP_gnomAD_exomes_controls_EAS_nhomalt|dbNSFP_gnomAD_exomes_controls_FIN_AF|dbNSFP_gnomAD_exomes_controls_FIN_nhomalt|dbNSFP_gnomAD_exomes_controls_NFE_AF|dbNSFP_gnomAD_exomes_controls_NFE_nhomalt|dbNSFP_gnomAD_exomes_controls_POPMAX_AF|dbNSFP_gnomAD_exomes_controls_POPMAX_nhomalt|dbNSFP_gnomAD_exomes_controls_SAS_AF|dbNSFP_gnomAD_exomes_controls_SAS_nhomalt|dbNSFP_gnomAD_exomes_controls_nhomalt|dbNSFP_gnomAD_exomes_nhomalt|dbNSFP_gnomAD_genomes_AF|dbNSFP_gnomAD_genomes_AFR_AF|dbNSFP_gnomAD_genomes_AFR_nhomalt|dbNSFP_gnomAD_genomes_AMR_AF|dbNSFP_gnomAD_genomes_AMR_nhomalt|dbNSFP_gnomAD_genomes_ASJ_AF|dbNSFP_gnomAD_genomes_ASJ_nhomalt|dbNSFP_gnomAD_genomes_EAS_AF|dbNSFP_gnomAD_genomes_EAS_nhomalt|dbNSFP_gnomAD_genomes_FIN_AF|dbNSFP_gnomAD_genomes_FIN_nhomalt|dbNSFP_gnomAD_genomes_NFE_AF|dbNSFP_gnomAD_genomes_NFE_nhomalt|dbNSFP_gnomAD_genomes_POPMAX_AF|dbNSFP_gnomAD_genomes_POPMAX_nhomalt|dbNSFP_gnomAD_genomes_controls_AF|dbNSFP_gnomAD_genomes_controls_AFR_AF|dbNSFP_gnomAD_genomes_controls_AFR_nhomalt|dbNSFP_gnomAD_genomes_controls_AMR_AF|dbNSFP_gnomAD_genomes_controls_AMR_nhomalt|dbNSFP_gnomAD_genomes_controls_ASJ_AF|dbNSFP_gnomAD_genomes_controls_ASJ_nhomalt|dbNSFP_gnomAD_genomes_controls_EAS_AF|dbNSFP_gnomAD_genomes_controls_EAS_nhomalt|dbNSFP_gnomAD_genomes_controls_FIN_AF|dbNSFP_gnomAD_genomes_controls_FIN_nhomalt|dbNSFP_gnomAD_genomes_controls_NFE_AF|dbNSFP_gnomAD_genomes_controls_NFE_nhomalt|dbNSFP_gnomAD_genomes_controls_POPMAX_AF|dbNSFP_gnomAD_genomes_controls_POPMAX_nhomalt|dbNSFP_gnomAD_genomes_nhomalt|nhomalt_afr|nhomalt_afr_female|nhomalt_afr_male|nhomalt_ami|nhomalt_ami_female|nhomalt_ami_male|nhomalt_amr|nhomalt_amr_female|nhomalt_amr_male|nhomalt_asj|nhomalt_asj_female|nhomalt_asj_male|nhomalt_eas|nhomalt_eas_female|nhomalt_eas_male|nhomalt_female|nhomalt_fin|nhomalt_fin_female|nhomalt_fin_male|nhomalt_male|nhomalt_nfe|nhomalt_nfe_female|nhomalt_nfe_male|nhomalt_oth|nhomalt_oth_female|nhomalt_oth_male|nhomalt_raw|nhomalt_sas|nhomalt_sas_female|nhomalt_sas_male) / /g')
		fields=$fieldsclean

	else
		#Unpopulated fields, overpopulation and tablesanity their worst enemy.
		# Cannot tackle em or else the field spacing indels vs snv will get borked
		# because some annotations are snv specific.
		fields="${variantFields}"
		#(
		#	originallist="$(DumpFieldsForVariantsToTable.pl '${vcf}')";
		#	newfields="";
		#	for f in $fields; do 
		#		fieldpresent=0
		#		for tf in $originallist; do
		#			if [ "$f" = "$tf" ] ; then 
		#				fieldpresent=1;
		#			fi;
		#		done; 
		#		if [ $fieldpresent = 0 ] ; then 
		#			echo "$f aint present";
		#			else newfields="$newfields $f";
		#		fi ;
		#	done; 
		#	echo $newfields
		#	if [ "$fields" = "$newfields" ] ; then
		#		echo "fields correct"
		#	else
		#		echo -e "fields incorrect wih input vcf\ninput fields:$fields\nfields present in vcf:$newfields\n"
		#		exit 1 
		#	fi
		#)
	fi

	java -Xmx1g -Djava.io.tmpdir=${tableDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
	 -T VariantsToTable \
	 -R ${onekgGenomeFasta} \
	 -V ${vcf} \
	 -raw \
	 -F CHROM -F POS -F REF -F ALT -F ID -F QUAL -F FILTER $fields \
	 -o ${variantRawTable}

	java -Xmx1g -Djava.io.tmpdir=${tableDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
	 -T VariantsToTable \
	 -R ${onekgGenomeFasta} \
	 -V ${vcf} \
	 -F CHROM -F POS -F REF -F ALT -F ID -F QUAL -F FILTER $fields \
	 -o ${variantTable}
	#Depreciated in gatk 3.8
        #-AMD \

else
	touch ${variantTable}
	touch ${variantRawTable}
fi

putFile ${variantTable}
putFile ${variantRawTable}

echo "## "$(date)" ##  $0 Done "
