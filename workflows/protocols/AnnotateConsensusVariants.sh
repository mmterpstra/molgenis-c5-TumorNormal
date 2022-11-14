#MOLGENIS nodes=1 ppn=4 mem=14gb walltime=36:00:00

#string project
#string onekgGenomeFastaIdxBase


#Parameter mapping

#string stage
#string checkStage
#string pipelineUtilMod
#string picardMod
#string samtoolsMod

#string onekgGenomeFasta
#string annotateConsensusDir
#list consensusBam

#string combineScatVcf
#string annotateConsensusScatVcf

echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${annotateConsensusScatVcf}
 
#getFile functions


#Load modules
${stage} ${pipelineUtilMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${annotateConsensusDir}



for base in "${consensusBam[@]}"; do
	echo "getFile file='$base'"
	getFile "$base"
done
getFile ${combineScatVcf}

inputs=$(printf ' %s ' $(printf '%s\n' "${consensusBam[@]}" | perl -wpe 'chomp; my $file = $_;s!^.*\/!!g;s!\.bam$!!g;$_=$_.",".$file."\n";' | sort -u ))

AddFragCountsToVariantsSamtools.pl -v ${combineScatVcf} -f 0.08 $inputs > ${annotateConsensusScatVcf}


putFile ${annotateConsensusScatVcf}


echo "## "$(date)" ##  $0 Done "



