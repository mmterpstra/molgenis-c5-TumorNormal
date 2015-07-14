#MOLGENIS nodes=1 ppn=1 mem=6gb walltime=10:00:00


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string intermediateDir
#string MergeBamFilesBam
#string MergeBamFilesBai

#string macs2Version
#string macs2Dir
#string macs2Base
#string sampleName

alloutputsexist \
	${macs2Dir}/${sampleName}_summits.bed \
	${macs2Dir}/${sampleName}_model.r

${stage} macs2/${macs2Version}
${checkStage}


getFile ${MergeBamFilesBam}
getFile ${MergeBamFilesBai}

set -x
set -e

mkdir -p ${macs2Dir}

#pseudo
#macs2 callpeak -t treat.bam [-c control.bam] -f AUTO -n treat[_vs_control] -g hs --outdir out/ -q 0.01

#macs2 callpeak -t ${MergeBamFilesBam} -c control.bam -f AUTO -n ${sampleName}_vs_${controlName} -g hs --outdir ${macs2Dir} -q 0.01


#nocontrol

macs2 callpeak \
 -t ${MergeBamFilesBam} \
 -f AUTO -n ${sampleName} \
 -g hs \
 --outdir ${macs2Dir} \
 -q 0.01 \
 --bdg
 
