#MOLGENIS walltime=23:59:00 mem=10gb

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

