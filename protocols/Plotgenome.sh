#MOLGENIS walltime=23:59:00 mem=1gb

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


##you can also add an F score to the genotypes (based on AD) and integrate it into the plot == added value
##a string tmpSnpVariantsTableTable {intermediateDir}/tmp/{project}.SnpsToTab.tab.table

##echo.....
#Check if output exists

alloutputsexist \
"${segFile}" \
"${segmentsPlotPdf}" \
"${cnvPlotPdf}" 

#getfile declarations
getFile ${varscanCopycaller}
getFile ${varscanCopycallerHomdels}
getfile ${onekgGenomeFastaDict}

#load modules
${stage} ${RMod}
${stage} ${pipelineUtilMod}

#
$checkStage
#run script perl PlotFloatsOnInterVals0.0.2.pl -R Rscript -d $dictFile $varscanCopycaller [variantstable.table]

set -x
set -e

oldDirName=$(pwd)

cd $(dirname ${varscanCopycaller})

perl $EBROOTPIPELINEMINUTIL/bin/${plotScriptPl} \
 -R Rscript \
 -d ${onekgGenomeFastaDict} \
 -v ${snvRawTable} \
 ${varscanCopycaller} \
 
cd $(dirname ${varscanCopycaller})

cd $oldDirName

# $vcf
putFile "${segFile}"
putFile "${segmentsPlotPdf}"
putFile "${cnvPlotPdf}"

