#MOLGENIS walltime=23:59:00 mem=20gb ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string onekgGenomeFasta
#string markDuplicatesBam,markDuplicatesBai

#string samtoolsMod
#string mantaMod
#string mantaConfigType
#string mantaDir
#string mantaRunDir
#string mantaVcf
#string mantaVcfIdx

alloutputsexist \
"${mantaDir}" \
"${mantaVcf}"

echo "## "$(date)" ##  $0 Started "


for file in "${onekgGenomeFasta}" "${markDuplicatesBam[@]}" "${markDuplicatesBai[@]}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load module
${stage} ${samtoolsMod}
${stage} ${mantaMod}
${checkStage}

set -x
set -e

# sort unique and print like '--bam=file1.bam --bam=file2.bam '
bamsu=($(printf '%s\n' "${markDuplicatesBam[@]}" | sort -u ))

declare -a bams

for bam in "${bamsu[@]}" ; do
	if [ $(samtools view -c -f 1  $bam) -ge 1 ]; then
		bams+=($bam)
	else
		echo "SE, Skipped "$bam"'"
	fi;
done

if [ ${#bams[*]} -ge 1 ]; then

	inputs=$(printf ' --bam=%s ' $(printf '%s\n' ${bams[@]}))

	mkdir -p ${mantaDir}
	mkdir ${mantaRunDir}
	#pseudo: 
	#configManta.py --bam=FILE --exome --referenceFasta=FILE --runDir=DIR 
	#python ${mantaDir}/runWorkflow.py -m local -j 1 -g 20
	configManta.py \
	 $inputs \
	 ${mantaConfigType} \
	 --referenceFasta=${onekgGenomeFasta} \
	 --runDir=${mantaRunDir}

	python ${mantaRunDir}/runWorkflow.py \
	 -m local \
	 -j 1 \
	 -g 20

else
	echo "Manta sv detection skipped because no PE reads present in bamfiles"
	mkdir -p $(dirname ${mantaVcf})
	touch ${mantaVcf}
	touch ${mantaVcfIdx}
	touch ${mantaVcf}.pefail
fi

putFile ${mantaVcf}
putFile ${mantaVcfIdx}

echo "## "$(date)" ##  $0 Done "
