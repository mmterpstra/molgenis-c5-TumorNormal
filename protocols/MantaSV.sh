#MOLGENIS walltime=23:59:00 mem=9gb ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string onekgGenomeFasta
#list bqsrBam,bqsrBai

#string mantaMod
#string mantaDir
#string mantaVcf
#string mantaVcfIdx

alloutputsexist \
"${mantaDir}" \
"${mantaVcf}"

echo "## "$(date)" ##  $0 Started "


#tired of typing getfile....

for file in "${onekgGenomeFasta}" "${bqsrBam[@]}" "${bqsrBai[@]}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load module
${stage} ${mantaMod}
${checkStage}

set -x
set -e

# sort unique and print like '--bam=file1.bam --bam=file2.bam '
bams=($(printf '%s\n' "${bqsrBam[@]}" | sort -u ))
inputs=$(printf ' --bam=%s ' $(printf '%s\n' ${bams[@]}))

mkdir -p ${mantaDir}

#pseudo: #configManta.py --bam=FILE --exome --referenceFasta=FILE --runDir=DIR
configManta.py \
 $inputs \
 --exome \
 --referenceFasta=${onekgGenomeFasta} \
 --runDir=${mantaDir}

putFile ${mantaVcf}
putFile ${mantaVcfIdx}

echo "## "$(date)" ##  $0 Done "
