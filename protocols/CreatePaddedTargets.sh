#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4


#string stage
#string checkStage
#string picardMod
#string projectDir

#string targetsList
#string slopTargetsList
#string scatterIntervallistDir
#list scatterIDs,scatterList

#scatList scatIds need to be here because of molgenis duplicating array values
scatIds=($(printf '%s\n' "${scatterIDs[@]}" | sort -u ))
scatList=($(printf '%s\n' "${scatterList[@]}" | sort -u ))
scatCount=$(printf '%s\n' "${scatIds[@]}" | wc -l )

#alloutputsext
alloutputsexist \
 ${slopTargetsList} \
 ${scatList[*]} 
 

echo "## "$(date)" Start $0"

getFile ${targetsList}

#load modules
${stage} ${picardMod}
${checkStage}

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${projectDir}

if [ ${#targetsList} -ne 0 ]; then
	
	#Run Picard
	java -jar  -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar IntervalListTools \
	 INPUT=${targetsList} \
	 OUTPUT=${slopTargetsList} \
	 PADDING=150 \
	 UNIQUE=true \
	 COMMENT="Added padding of 100bp and merge overlapping and adjacent intervals to create a list of unique intervals PADDING=150 UNIQUE=true"
	
	putFile ${slopTargetsList}
	
	echo "scatCount="$scatCount" countofids="${#scatterIDs[@]}" Ids="${scatterIDs[*]} 
	
	mkdir -p ${scatterIntervallistDir}
	
	java -jar  -Xmx4g -XX:ParallelGCThreads=4 $EBROOTPICARD/picard.jar IntervalListTools \
	 INPUT=${targetsList} \
	 OUTPUT=${scatterIntervallistDir} \
	 PADDING=150 \
	 UNIQUE=true \
	 SCATTER_COUNT=$scatCount \
	 COMMENT="Added padding of 100bp and merge overlapping and adjacent intervals to create a list of unique intervals PADDING=150 UNIQUE=true"
	
	for l in ${scatList[*]}; do 
		if [ -e $l ]; then 
			putFile $l
		fi
	done

fi

echo "## "$(date)" ##  $0 Done "
