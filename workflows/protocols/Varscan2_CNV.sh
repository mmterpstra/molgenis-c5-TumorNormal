#MOLGENIS walltime=195:59:00 mem=1gb ppn=1 nodes=1

#string project



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


if [ $(grep -c "ERROR: Gave up waiting after 500 seconds..." ${varscanCopynumberPrefix}.err.log) -ge 1 ] ;then
	echo "## "$(date)" ## Varscan2 copynumber inputlag fail please restart" >&2
	echo "## "$(date)" ## Varscan2 copynumber inputlag fail please restart"
	rm ${varscanCopynumber} 
	exit 1
fi

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
#MOLGENIS walltime=23:59:00 mem=3gb

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string onekgGenomeFastaDict
#string varscanCopycaller
#string varscanCopycallerHomdels
#string RMod
#string pipelineUtilMod
#string plotScriptPl
#string snvRawTable
#string segFile
#string segmentsPlotPdf
#string cnvPlotPdf

set -e
set -x

##you can also add an F score to the genotypes (based on AD) and integrate it into the plot == added value
##a string tmpSnpVariantsTableTable {intermediateDir}/tmp/{project}.SnpsToTab.tab.table

##echo.....
#Check if output exists

alloutputsexist \
"${segFile}" \
"${cnvPlotPdf}" 

#getfile declarations
getFile ${varscanCopycaller}
getFile ${varscanCopycallerHomdels}
getFile ${onekgGenomeFastaDict}

#load modules
${stage} ${RMod}
${stage} ${pipelineUtilMod}

#
${checkStage}

#run script perl PlotFloatsOnInterVals0.0.2.pl -R Rscript -d $dictFile $varscanCopycaller [variantstable.table]

oldDirName=$(pwd)

varscanlines=$(cat ${varscanCopycaller} | wc -l)
if [ $varscanlines -gt 100 ] ; then

	echo "Varscan lines found. plotting genome."

	cd $(dirname ${varscanCopycaller})

	perl $EBROOTPIPELINEMINUTIL/bin/${plotScriptPl} \
	 -R Rscript \
	 -d ${onekgGenomeFastaDict} \
	 -v ${snvRawTable} \
	 ${varscanCopycaller}

	cd $oldDirName


else
	echo "No varscan lines found. skipping."
	touch "${segFile}" \
	 "${cnvPlotPdf}" 
fi


# $vcf
putFile "${segFile}"
putFile "${cnvPlotPdf}"

