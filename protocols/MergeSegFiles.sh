#MOLGENIS walltime=23:59:00 mem=1gb

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string onekgGenomeFastaDict
#string varscanDir
#string RMod
#string pipelineUtilMod
#string snvRawTable
#list segFile

set -e
set -x

##you can also add an F score to the genotypes (based on AD) and integrate it into the plot == added value
##a string tmpSnpVariantsTableTable {intermediateDir}/tmp/{project}.SnpsToTab.tab.table

##echo.....
#Check if output exists

alloutputsexist \
 "${varscanDir}/multi"

#getFile declarations
for file in $( "${segFile[@]}" ${onekgGenomeFastaDict}); do 
	getFile $file
done

#load modules
${stage} ${RMod}
${stage} ${pipelineUtilMod}
#${stage} ${bedtoolsMod}?
#
${checkStage}


segs=($(printf '%s\n' "${segFile[@]}" | sort -u ))

segList=()

for seg in "${segs[@]}"; do
	getFile $seg
	if [ -e $seg ]; then
		echo "added $seg to merge list";
		segList+=("$seg")
	fi
done


mkdir -p ${varscanDir}"/multi"

perl $EBROOTPIPELINEMINUTIL/bin/multiIntersectSeg.pl ${onekgGenomeFastaDict} ${varscanDir}"/multi" $( printf ' %s'  ${segList[@]})

putFile ${varscanDir}/multi
# $vcf

echo "## "$(date)" ##  $0 Done "

