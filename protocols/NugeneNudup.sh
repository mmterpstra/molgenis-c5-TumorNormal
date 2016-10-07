#MOLGENIS nodes=1 ppn=8 mem=8gb walltime=10:00:00

#string project



#Parameter mapping
#string stage
#string checkStage
#string picardMod
#string samtoolsMod
#string nudupMod
#string digiRgMod
#string reads3FqGz
#string reads2FqGz
#string addOrReplaceGroupsBam
#string addOrReplaceGroupsBai


#string nugeneRgDir
#string nugeneBam
#string nugeneBai

echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${nugeneBam} ${nugeneBai}
 
#getFile functions

getFile ${addOrReplaceGroupsBam}
getFile ${addOrReplaceGroupsBai}

#Load modules
${stage} ${nudupMod}
${stage} ${picardMod}
#check modules
${checkStage}


set -x
set -e

mkdir -p ${nugeneRgDir}

echo "## "$(date)" Start $0"

if [ ${#reads3FqGz} -eq 0 ]; then

	cp -rv ${addOrReplaceGroupsBai} ${addOrReplaceGroupsBam} ${nugeneRgDir}

else
	#pseudo python $EBROOTNUDUPPY/nudup.py -2 -o OUTPREFIX -l 6 IN.bam
	if [ ${#reads2FqGz} -eq 0 ]; then
		python $EBROOTNUDUPPY/nudup.py -o ${nugeneBam} -l 6 ${addOrReplaceGroupsBam}
	else
		python $EBROOTNUDUPPY/nudup.py -2 -o ${nugeneBam} -l 6 ${addOrReplaceGroupsBam}
	fi
	
	mv ${nugeneBam}.sorted.markdup.bam ${nugeneBam}
 	#exit 1 

	java -Xmx6g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar BuildBamIndex \
	 INPUT=${nugeneBam}

fi

putFile ${nugeneBam} 
putFile ${nugeneBai} 

echo "## "$(date)" ##  $0 Done"
