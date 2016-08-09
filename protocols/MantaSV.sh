#MOLGENIS walltime=23:59:00 mem=20gb ppn=10

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string onekgGenomeFasta
#list markDuplicatesBam,markDuplicatesBai


#string mantaMod
#string mantaConfigType
#string mantaDir
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
${stage} ${mantaMod}
${checkStage}

set -x
set -e

# sort unique and print like '--bam=file1.bam --bam=file2.bam '
bams=($(printf '%s\n' "${markDuplicatesBam[@]}" | sort -u ))
inputs=$(printf ' --bam=%s ' $(printf '%s\n' ${bams[@]}))

mkdir -p ${mantaDir}

#pseudo: 
#configManta.py --bam=FILE --exome --referenceFasta=FILE --runDir=DIR 
#python ${mantaDir}/runWorkflow.py -m local -j 10 -g 20
configManta.py \
 $inputs \
 ${mantaConfigType} \
 --referenceFasta=${onekgGenomeFasta} \
 --runDir=${mantaDir}

python ${mantaDir}/runWorkflow.py \
 -m local \
 -j 10 \
 -g 20

putFile ${mantaVcf}
putFile ${mantaVcfIdx}

echo "## "$(date)" ##  $0 Done "
