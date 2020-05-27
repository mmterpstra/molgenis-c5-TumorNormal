#MOLGENIS walltime=167:59:00 mem=5gb ppn=1 nodes=1

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string varScanMod
#string samtoolsMod
#string bedtoolsMod

#string varscanCopynumberPrefix
#string varscanCopynumber
#string varscanCopycaller
#string varscanCopycallerHomdels
#string varscanDir

#string indelRealignmentBam
#string indelRealignmentBai
#string indelRealignmentBamBai

#string controlSampleBam
#string controlSampleBai
#string controlSampleBamBai

#string onekgGenomeFastaDict
#string onekgGenomeFasta
#string targetsList

echo "## "$(date)" ##  $0 Started "

#Check if output exists
alloutputsexist \
"${varscanCopynumber}" \
"${varscanCopycaller}" \
"${varscanCopycallerHomdels}"

mkdir -p ${varscanDir}

#getfile decl
getFile ${onekgGenomeFasta}
getFile ${onekgGenomeFastaDict}
getFile ${indelRealignmentBam}
getFile ${indelRealignmentBai}
getFile ${indelRealignmentBamBai}
getFile ${controlSampleBam}
getFile ${controlSampleBai}
getFile ${controlSampleBamBai}
getFile ${targetsList}

#Load modules
${stage} ${varScanMod}
${stage} ${samtoolsMod}
${stage} ${bedtoolsMod}

${checkStage}
set -x -e -o pipefail

#this program performs data reduction of the bam files by selecting intervals and collecting statistics on the intervals

echo -n ""> ${varscanCopynumber} 
echo -n ""> ${varscanCopycaller}
echo -n ""> ${varscanCopycaller}

#create bedfile on the fly
 grep -v '^@' ${targetsList} | perl -wlane 'print join("\t",($F[0],$F[1]-1,$F[2],$.));' |bedtools slop -b 300 -g <(cut -f1,2 ${onekgGenomeFasta}.fai) -i ->  ${varscanCopynumberPrefix}.intervals.bed


# cnv data collection
samtools mpileup \
 -R -q 40 -f ${onekgGenomeFasta} \
 ${controlSampleBam} ${indelRealignmentBam} | \
 java -Xmx4g -jar $EBROOTVARSCAN/VarScan.*.jar copynumber \
  - ${varscanCopynumberPrefix} \
  --mpileup --min-segment-size 2000 --max-segment-size 5000 --min-coverage 1 2> ${varscanCopynumberPrefix}.err.log
cat ${varscanCopynumberPrefix}.err.log >&2


cat ${varscanCopynumberPrefix}.err.log >&2

#check for input lag of varscan
if [ $(grep -c "ERROR: Gave up waiting after 500 seconds..." ${varscanCopynumberPrefix}.err.log) -ge 1 ] ;then
	echo "## "$(date)" ## Varscan2 copynumber inputlag fail please restart" >&2
	echo "## "$(date)" ## Varscan2 copynumber inputlag fail please restart"
	rm ${varscanCopynumber} 
	exit 1
fi

rm -v ${varscanCopynumberPrefix}.intervals.bed

java -jar -Xmx4g -jar $EBROOTVARSCAN/VarScan.*.jar copyCaller ${varscanCopynumber} --output-file ${varscanCopycaller} --output-homdel-file ${varscanCopycallerHomdels}

if [ -z ${varscanCopynumber} ] || [ -z ${varscanCopycaller} ] || [ -z ${varscanCopycaller} ] ; then
 
	echo "removed ${varscanCopynumber} ${varscanCopycaller} ${varscanCopycaller} because of 0-size"
	rm -v ${varscanCopynumber} ${varscanCopycaller} ${varscanCopycaller}
	exit 1
fi

putFile ${varscanCopynumber}
putFile ${varscanCopycaller}
putFile ${varscanCopycallerHomdels}

echo "## "$(date)" ##  $0 Done"
