#MOLGENIS walltime=23:59:00 mem=6gb ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string picardMod


#string addOrReplaceGroupsDir
#list addOrReplaceGroupsBam,addOrReplaceGroupsBai,scatterIDs

#string mergeBamFilesDir
#string mergeBamFilesBam
#string mergeBamFilesBai


alloutputsexist \
"${mergeBamFilesBam}" \
"${mergeBamFilesBai}"

echo "## "$(date)" ##  $0 Started "

for file in "${addOrReplaceGroupsBam[@]}" "${addOrReplaceGroupsBai[@]}" ; do
	echo "getFile file='$file'"
	getFile $file
done

#Load Picard module
${stage} ${picardMod}
${checkStage}

set -o posix

set -x
set -e

#${addOrReplaceGroupsBam} sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n' "${addOrReplaceGroupsBam[@]}" | sort -u ))
inputs=$(printf 'INPUT=%s ' $(printf '%s\n' ${bams[@]}))

mkdir -p ${mergeBamFilesDir}

java -Xmx6g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar MergeSamFiles \
 $inputs \
 SORT_ORDER=coordinate \
 CREATE_INDEX=true \
 USE_THREADING=true \
 TMP_DIR=${mergeBamFilesDir} \
 MAX_RECORDS_IN_RAM=6000000 \
 OUTPUT=${mergeBamFilesBam} \

# VALIDATION_STRINGENCY=LENIENT \

putFile ${mergeBamFilesBam}
putFile ${mergeBamFilesBai}

echo "## "$(date)" ##  $0 Done "
