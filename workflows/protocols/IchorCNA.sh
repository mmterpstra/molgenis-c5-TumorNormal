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
#string ichorcnaChromosomes
#string ichorcnaChrs
#string ichorcnaChrtrain
#string coverageWig
#string ichorcnaPdf
#string mapability1000kbWig
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
 --chromosome $(echo "${ichorcnaChromosomes}"| perl -wpe 's/\t/,/g') \
 ${indelRealignmentBam} > ${coverageWig}
readCounter\
 --window 1000000 \
 --quality 20 \
 --chromosome $(echo "${ichorcnaChromosomes}"| perl -wpe 's/\t/,/g') \
 ${controlSampleBam} > ${coverageWig}_norm.wig

#NCBI
#BSgenome.Hsapiens.1000genomes.hs37d5
runIchorCNA.R \
 --WIG  ${coverageWig} \
 --NORMWIG  ${coverageWig}_norm.wig \
 --gcWig ${onekgGenomeFasta}.gc.wig \
 --id t_$(basename ${coverageWig} .wig)_n_$(basename ${controlSampleBam} .bam) \
 --outDir=${ichorcnaDir} \
 --mapWig=$EBROOTRMINBUNDLEMINICHORCNA/ichorCNA/extdata/${mapability1000kbWig} \
 --genomeBuild="hg38" \
 --genomeStyle="NCBI" \
 --estimateScPrevalence FALSE --scStates "c()" \
 --chrs $(echo "${ichorcnaChrs}"| perl -wpe 's/\t/,/g') \
 --chrTrain $(echo "${ichorcnaChrtrain}"| perl -wpe 's/\t/,/g') \
 --chrNormalize $(echo "${ichorcnaChrs}"| perl -wpe 's/\t/,/g') \
 --normal "c(0.5,0.75,0.85,0.9,0.95)" 

putFile ${ichorcnaDir}/t_$(basename ${coverageWig} .wig)_n_$(basename ${controlSampleBam} .bam)
#putFile ${ichorcnaDir}


echo "## "$(date)" ##  $0 Done "
