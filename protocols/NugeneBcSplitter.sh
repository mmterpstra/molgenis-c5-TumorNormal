#MOLGENIS nodes=1 ppn=8 mem=8gb walltime=10:00:00

#string project



#Parameter mapping
#string stage
#string checkStage
#string picardMod
#string samtoolsMod
#string reads3FqGz
#string addOrReplaceGroupsBam
#string addOrReplaceGroupsBai

#string nugBcSplitterPl
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
${stage} ${samtoolsMod}
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
	
	perl ${nugBcSplitterPl} ${addOrReplaceGroupsBam} ${nugeneBam}
	
	java -Xmx6g -XX:ParallelGCThreads=4 -jar $EBROOTPICARD/picard.jar BuildBamIndex \
 INPUT=${nugeneBam}	

fi

putFile ${nugeneBam} 
putFile ${nugeneBai} 

echo "## "$(date)" ##  $0 Done"
