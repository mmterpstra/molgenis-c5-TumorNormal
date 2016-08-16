#MOLGENIS walltime=23:59:00 mem=8gb ppn=1

#string project

#Parameter mapping
#string stage
#string checkStage
#string projectDir
#string snpEffMod



#string mantaDir
#string mantaVcf
#string mantaVcfIdx
#string snpeffMantaDir
#string snpeffMantaVcf
#string snpeffMantaVcfIdx
#string snpEffMantaStats

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
${checkStage}

set -x
set -e

mkdir -p ${snpeffMantaDir}

java -Xmx8g -jar  $EBROOTSNPEFF/snpEff.jar \
 -c $EBROOTSNPEFF/snpEff.config \
 -dataDir ${snpeffDataDir} \
 -hgvs \
 -lof \
 -stats ${snpEffMantaStats} \
 -v \
 GRCh37.75 \
 ${mantaVcf} \
 1>${snpeffMantaVcf}

putFile ${snpEffMantaStats}
putFile ${snpeffMantaVcf}

echo "## "$(date)" ##  $0 Done "

