#MOLGENIS nodes=1 ppn=1 mem=10gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string ichorcnaMod
#string onekgGenomeFasta
#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai
#string controlSampleBam
#string controlSampleBai
#string ichorcnaDir
#string coverageWig
#string ichorcnaPdf

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${ichorcnaDir}/t_$(basename ${coverageWig} .wig)_n_$(basename ${controlSampleBam} .bam) 

${stage} ${ichorcnaMod} 
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${indelRealignmentBam}
getFile ${indelRealignmentBai}
getFile ${controlSampleBam}
getFile ${controlSampleBai}
getFile ${onekgGenomeFasta}.gc.wig

set -x
set -e

mkdir -p ${ichorcnaDir}


Normalspec=""

readCounter\
 --window 1000000 \
 --quality 20 \
 --chromosome "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X,Y" \
 ${indelRealignmentBam} > ${coverageWig}
readCounter\
 --window 1000000 \
 --quality 20 \
 --chromosome "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X,Y" \
 ${controlSampleBam} > ${coverageWig}_norm.wig



runIchorCNA.R \
 --WIG  ${coverageWig} \
 --NORMWIG  ${coverageWig}_norm.wig \
 --gcWig ${onekgGenomeFasta}.gc.wig \
 --id t_$(basename ${coverageWig} .wig)_n_$(basename ${controlSampleBam} .bam) \
 --outDir=${ichorcnaDir} \
 --mapWig=$EBROOTRMINBUNDLEMINICHORCNA/ichorCNA/extdata/map_hg19_1000kb.wig \
 --estimateScPrevalence FALSE --scStates "c()" \
 --chrs "c(1:22)" --chrTrain "c(1:18,20:22)" \
 --normal "c(0.5,0.75,0.85,0.9,0.95)" 

putFile ${ichorcnaDir}/t_$(basename ${coverageWig} .wig)_n_$(basename ${controlSampleBam} .bam)
#putFile ${ichorcnaDir}


echo "## "$(date)" ##  $0 Done "
