#MOLGENIS walltime=23:59:00 mem=1gb ppn=1 nodes=1


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string varScanMod
#string samtoolsMod

#string varscanCopynumberPrefix
#string varscanCopynumber
#string varscanCopycaller
#string varscanCopycallerHomdels
#string varscanDir

#string varscanInputBam
#string varscanInputBai
#string varscanInputBamBai

#string controlvarscanInputBam
#string controlvarscanInputBai
#string controlvarscanInputBamBai

#string onekgGenomeFastaDict
#string onekgGenomeFasta

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
getFile ${varscanInputBam}
getFile ${varscanInputBai}
getFile ${varscanInputBamBai}
getFile ${controlvarscanInputBam}
getFile ${controlvarscanInputBai}
getFile ${controlvarscanInputBamBai}

#Load modules
${stage} ${varScanMod}
${stage} ${samtoolsMod}


${checkStage}
set -x
set -e

#this program performs data reduction of the bam files by selecting intervals and collecting statistics on the intervals

echo -n ""> ${varscanCopynumber} 
echo -n ""> ${varscanCopycaller}
echo -n ""> ${varscanCopycaller}

samtools mpileup \
 -R -q 40 -f ${onekgGenomeFasta} \
 ${controlvarscanInputBam} ${varscanInputBam} | \
 java -Xmx4g -jar $EBROOTVARSCAN/VarScan.*.jar copynumber \
  - ${varscanCopynumberPrefix} \
  --mpileup --min-segment-size 2000 --max-segment-size 5000 --min-coverage 1 2> ${varscanCopynumberPrefix}.err.log
cat ${varscanCopynumberPrefix}.err.log >&2

count=$(grep -c "ERROR: Gave up waiting after 500 seconds..." ${varscanCopynumberPrefix}.err.log)
if [ "$count" -ge 1 ] ;then
	echo "## "$(date)" ## Varscan2 copynumber inputlag fail please restart" >&2
	echo "## "$(date)" ## Varscan2 copynumber inputlag fail please restart"
	rm ${varscanCopynumber} 
	exit 1
fi

java -jar -Xmx4g -jar $EBROOTVARSCAN/VarScan.*.jar copyCaller ${varscanCopynumber} --output-file ${varscanCopycaller} --output-homdel-file ${varscanCopycallerHomdels}

if [ -z ${varscanCopynumber} ] || [ -z ${varscanCopycaller} ] || [ -z ${varscanCopycaller} ] ; then
 
	echo "removed ${varscanCopynumber} ${varscanCopycaller} ${varscanCopycaller} because of 0-size"
	rm ${varscanCopynumber} ${varscanCopycaller} ${varscanCopycaller}
	exit 1
fi

putFile ${varscanCopynumber}
putFile ${varscanCopycaller}
putFile ${varscanCopycallerHomdels}

echo "## "$(date)" ##  $0 Done"
