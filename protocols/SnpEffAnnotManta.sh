#MOLGENIS walltime=23:59:00 mem=8gb ppn=1

#string project

#Parameter mapping
#string stage
#string checkStage
#string projectDir
#string snpEffMod
#string snpeffDataDir
#string vcfToolsMod
#string pipelineUtilMod

#string mantaDir
#string mantaVcf
#string mantaVcfIdx
#string snpeffMantaDir
#string snpeffMantaVcf
#string snpeffMantaVcfIdx
#string snpEffMantaStats

##string motifBin
##string nextProtBin
##string pwmsBin
##string regulation_CD4Bin
##string regulation_GM06990Bin
##string regulation_GM12878Bin
##string regulation_H1ESCBin
##string regulation_HeLaS3Bin
##string regulation_HepG2Bin
##string regulation_HMECBin
##string regulation_HSMMBin
##string regulation_HUVECBin
##string regulation_IMR90Bin
##string regulation_K562Bin
##string regulation_NHABin
##string regulation_NHEKBin
#string snpEffectPredictorBin


alloutputsexist \
"${snpeffMantaVcf}" \
"${snpEffMantaStats}"

echo "## "$(date)" ##  $0 Started "


for file in "${mantaVcf}" "${mantaVcfIdx}" "${regulation_CD4Bin}"  "${regulation_GM06990Bin}"  "${regulation_GM12878Bin}"  "${regulation_H1ESCBin}"  "${regulation_HeLaS3Bin}"  "${regulation_HepG2Bin}"  "${regulation_HMECBin}"  "${regulation_HSMMBin}"  "${regulation_HUVECBin}"  "${regulation_IMR90Bin}"  "${regulation_K562Bin}"  "${regulation_NHABin}"  "${regulation_NHEKBin}"  "${snpEffectPredictorBin}" ; do
	echo "getFile file='$file'"
	getFile $file
done

#Load module
${stage} ${snpEffMod}
${stage} ${vcfToolsMod}
${stage} ${pipelineUtilMod}
${checkStage}

${checkStage}

set -x
set -e

mkdir -p ${snpeffMantaDir}


if [ $(grep -v '^#' ${mantaVcf} | wc -l ) -ge 1 ]; then
	(echo "##fileformat=VCFv4.1";
	zcat  ${mantaVcf} | \
	grep -vP "^##contig=<ID=hs37d5,length=35477943>|^hs37d5\t" /dev/stdin | \
	java -Xmx8g -jar $EBROOTSNPEFF/snpEff.jar \
	 -c $EBROOTSNPEFF/snpEff.config \
	 -dataDir ${snpeffDataDir} \
	 -hgvs \
	 -lof \
	 -stats ${snpEffMantaStats} -csvStats \
	 -v \
	 GRCh37.75  | \
	perl $EBROOTPIPELINEMINUTIL/bin/VcfSnpEffAsGatk.pl \
	 /dev/stdin \
	 ) > ${snpeffMantaVcf}


else
	echo "SE, Skipped"
	touch ${snpEffMantaStats}
        touch ${snpeffMantaVcf}

fi;

putFile ${snpEffMantaStats}
putFile ${snpeffMantaVcf}

echo "## "$(date)" ##  $0 Done "

