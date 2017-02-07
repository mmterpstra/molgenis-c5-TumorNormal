#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project



#string stage
#string RMod
#string RmarkMod
#string checkStage
#string sampleMarkdownDir
#string sampleMarkdown

#string sampleName
#list reads1FqGz,reads2FqGz,reads1FqGzClean,reads2FqGzClean

#string fastqcDir
#string fastqcCleanDir
#string collectMultipleMetricsPrefix

#string onekgGenomeFasta

#string markDuplicatesMetrics

#string calculateHsMetricsLog

alloutputsexist \
 ${sampleMarkdown}

echo "## "$(date)" Start $0"

#load modules
${stage} ${RMod}
${stage} ${RmarkMod}
${checkStage}

set -x
set -e

#main ceate dir and run programmes

mkdir -p ${sampleMarkdownDir}

(
	echo "Sample Info on:${sampleName}"
	echo "============================"
	echo "This document the analysis results of the sample :'${sampleName}'. Following the next steps of analysis:"
	echo ""

	echo "- **Fastq metrics**"
	echo "- **Hybrid selection metrics**"
	echo "- **Alignment metrics**"
	if [ -e ${markDuplicatesMetrics} ] ; then
		echo "- **Duplication removal metrics**"
	fi
	if [ ${#reads2FqGz} -ne 0 ]; then
		echo "- **Paired end metrics**"
	fi
	echo "- **Notes**"
	echo ""
	echo "For version tracking this document was generated on: '"$(date)"' and with script md5 of '"$(md5sum $0)"'"
	echo ""
) > ${sampleMarkdown}

################################################################################
##
#
(
	echo
	echo "Fastqc metrics"
	echo "==============="
	echo
	echo "This part is made using the output of the fastq program. If you want to read
 the doc [here it is](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/3%20Analysis%20Modules/)"
)>>  ${sampleMarkdown}

#main variables to extract from dataset
readNumberRaw=0
baseNumberRaw=0
readNumberClean=0
baseNumberClean=0
baseQ20pct=0
baseQ30pct=0

for fq in $(ls ${reads1FqGz[@]} ${reads2FqGz[@]}| perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g'| sort -u ); do
	if [ ${#fq} -ne 0 ] ; then
		for fastqcBasename in $(ls ${fastqcDir}/*${sampleName}"_fastqc/" -d); do
			cd ${fastqcBasename}
			unzip -u -o ${fastqcBasename}/$(echo -n $fq | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')"_fastqc".zip \*/fastqc_data.txt -d $(dirname ${fastqcBasename}) 
			readnumberfastq=$(grep 'Total Sequences'  ${fastqcBasename}//$(echo -n $fq | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')"_fastqc"/fastqc_data.txt | cut  -f2)
			let 'readNumberRaw=readNumberRaw+readnumberfastq'
			(
				echo
				echo "Raw fastqc data"
        			echo "----------------"
				echo
				echo "Below this paragraph the results of the fastqc tool are shown."
				echo

				#fastqcBasename=$(echo ${fastqcDir}/$(echo -n $fq | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')'_fastqc')

				perl -wne 'm/(\<div class\=\"main\"\>.*\<\/div\>)\<\/div\>/; print $1."\n" if defined $1;' \
				${fastqcBasename}/$(echo -n $fq | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')"_fastqc.html"


				echo
				cd ${fastqcDir}
				#unzip -u -o ${fastqcBasename}.zip \*/fastqc_data.txt
				#readNumberRaw
				#readnumberfastq=$(grep 'Total Sequences'  ${fastqcBasename}/fastqc_data.txt | cut  -f2)
				#let 'readNumberRaw=readNumberRaw+readnumberfastq'
			)>>${sampleMarkdown}

			cd $OLDPWD
		done
	fi
done

if [ -e ${fastqcCleanDir} ] ; then
       for fqClean in $(ls ${reads1FqGzClean[@]} ${reads2FqGzClean[@]}| sort -u ); do
		#if [ -e $fqClean ] ;then
		fastqcBasename=$(echo ${fastqcCleanDir}/$(echo -n $fqClean | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')'_fastqc')
		unzip -u -o ${fastqcBasename}.zip \*/fastqc_data.txt -d ${fastqcCleanDir}
		readnumberfastq=$(grep 'Total Sequences'  ${fastqcBasename}/fastqc_data.txt | cut  -f2)
		let 'readNumberClean=readNumberClean+readnumberfastq'

		(
			echo ""
	       		echo "Clean fastqc data"
	       		echo "----------------------"

				#fastqcBasename=$(echo ${fastqcCleanDir}/$(echo -n $fqClean | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')'_fastqc')

        		perl -wne 'm/(\<div class\=\"main\"\>.*\<\/div\>)\<\/div\>/; print $1."\n" if defined $1;' \
	        	 ${fastqcBasename}.html
			cd ${fastqcCleanDir}
			#this works \*/ yaay
		        #unzip -u -o ${fastqcBasename}.zip \*/fastqc_data.txt
			#readNumberClean
		        #readnumberfastq=$(grep 'Total Sequences'  ${fastqcBasename}/fastqc_data.txt | cut  -f2)
		        #let 'readNumberClean=readNumberClean+readnumberfastq'
		)>> ${sampleMarkdown}
		#fi
	done
fi

################################################################################
##
#

(
	echo
	echo "Fastq single sample summary data"
	echo "==============="
	echo
	echo "In the table below the output of metrics collection is shown. Meanings:"
	echo
	echo "- Reads raw: The initial amount of fastq reads after basecalling."
	echo "- Reads clean: The initial count of fastq reads after optionally filtering depending on the fastq origin."
	echo "- Bases clean: The count of fastq bases after optionally filtering depending on the fastq origin."
	echo "- Clean bases Q20: Percentage of bases having a quality score of >=20."
	echo "- Clean bases Q30: Percentage of bases having a quality score of >=30."
	echo
	echo -e "|\tsamplename\t|\tKey\t|\tValue\t|\tUnit\t|"
	echo -e "|\t----------\t|\t---\t|\t-----\t|\t----\t|"
	echo -e "|\t${sampleName}\t|\tReads raw\t|\t${readNumberRaw}\t|\tCount\t|"
	echo -e "|\t${sampleName}\t|\tReads clean\t|\t${readNumberClean}\t|\tCount\t|"

	baseNumberClean=$(awk '{if($1 >= 0){sum += $2}}; END { print sum }'  ${collectMultipleMetricsPrefix}.quality_distribution_metrics)
	echo -e "|\t${sampleName}\t|\tBases clean\t|\t${baseNumberClean}\t|\tCount\t|"

	baseQ20pct=$(awk '{if($1 >= 0){sum += $2}if($1 >= 20){sumQ20 += $2}}; END { print sumQ20/sum*100 }'  ${collectMultipleMetricsPrefix}.quality_distribution_metrics)
	echo -e "|\t${sampleName}\t|\tClean bases Q20\t|\t${baseQ20pct}\t|\tPercent\t|"

	baseQ30pct=$(awk '{if($1 >= 0){sum += $2}if($1 >= 30){sumQ30 += $2}}; END { print sumQ30/sum*100 }'  ${collectMultipleMetricsPrefix}.quality_distribution_metrics)

	echo -e "|\t${sampleName}\t|\tClean bases Q30\t|\t${baseQ30pct}\t|\tPercent\t|"
	echo

	echo -e "|\tsamplename\t|\tReads raw\t|\tReads clean\t|\tBases clean\t|\tClean bases Q20\t|\tClean bases Q30\t|"
	echo -e "|\t---\t|\t---\t|\t---\t|\t---\t|\t---\t|\t---\t|"

	echo -e "|\t${sampleName}\t|\t${readNumberRaw}\t|\t${readNumberClean}\t|\t${baseNumberClean}\t|\t${baseQ20pct}\t|\t${baseQ30pct}\t|"
)>>${sampleMarkdown}

################################################################################
##
#
(
	echo
	echo "Hybrid selection metrics"
	echo "========================"
	echo
	echo "**metrics definitions**"
	echo
	echo "literal source: http://broadinstitute.github.io/picard/picard-metric-definitions.html"
	echo
	echo "| field | description |"
	echo "| ----- | ----------- |"
	echo "| SAMPLE | The sample to which these metrics apply. If null, it means they apply to all reads in the file. |"
	echo "| READ_GROUP | The read group to which these metrics apply. If null, it means that the metrics were accumulated at the library or sample level."
	echo "| LIBRARY | The library to which these metrics apply. If null, it means that the metrics were accumulated at the sample level.|"
	echo "| TARGET_TERRITORY | The number of unique bases covered by the intervals of all targets that should be covered. |"
	echo "| PF_UQ_READS_ALIGNED | The number of PF unique reads that are aligned with mapping score > 0 to the reference genome. |"
	echo "| PF_UQ_BASES_ALIGNED | The number of PF unique bases that are aligned with mapping score > 0 to the reference genome. |"
	echo "| PF unique reads | The number of reads that pass the vendor's filter that are not marked as duplicates. |"
	echo "| ON_TARGET_BASES | The number of PF aligned bases that mapped to a targeted region of the genome.|"
	echo "| PCT_USABLE_BASES_ON_TARGET | The number of aligned, de-duped, on-target bases out of the PF bases available.|"
	echo "| MEAN_TARGET_COVERAGE | The mean coverage of targets that received at least coverage depth = 2 at one base.|"
	echo "| PCT_TARGET_BASES_2X | The percentage of ALL target bases achieving 2X or greater coverage.|"
	echo
	#the table
	echo "In the table below the output of metrics collection is shown."
	echo
	#hsmetrics
	echo 'tablehs=read.table("'${calculateHsMetricsLog}'", skip=6, header=TRUE, fill=NA, sep="\t");
	 write.table(subset(tablehs,SAMPLE != "",select=c("SAMPLE","TARGET_TERRITORY","PF_UQ_READS_ALIGNED","PF_UQ_BASES_ALIGNED",
	   "ON_TARGET_BASES","PCT_USABLE_BASES_ON_TARGET","MEAN_TARGET_COVERAGE","PCT_TARGET_BASES_2X","PCT_TARGET_BASES_10X",
	   "PCT_TARGET_BASES_20X", "PCT_TARGET_BASES_30X", "PCT_TARGET_BASES_40X", "PCT_TARGET_BASES_50X", "PCT_TARGET_BASES_100X"))
	 ,file=stdout(),sep="|", row.names=FALSE, quote=FALSE);' > ${sampleMarkdownDir}/${sampleName}_hsmetrics.R
	Rscript ${sampleMarkdownDir}/${sampleName}_hsmetrics.R | perl -wpe 'chomp $_; $_="| ".$_." |\n";if($.==1){print $_; $_ =~  s/[A-Z0-9\"\_]+/\ \-\-\-\ /g;}; '
	rm  ${sampleMarkdownDir}/${sampleName}_hsmetrics.R 
)>> ${sampleMarkdown}
################################################################################
##
#
(
	echo
	echo "Alignment metrics"
	echo "================="

	echo
	echo "**metrics definitions**"
	echo
	echo "literal source: http://broadinstitute.github.io/picard/picard-metric-definitions.html"
	echo
	echo "| field | description |"
	echo "| ----- | ----------- |"
	echo "| CATEGORY | One of either UNPAIRED (for a fragment run), FIRST_OF_PAIR when metrics are for only the first read in a paired run, SECOND_OF_PAIR when the metrics are for only the second read in a paired run or PAIR when the metrics are aggregated for both first and second reads in a pair. |"
	echo "| PF_READS | The number of PF reads where PF is defined as passing Illumina's filter. |"
	echo "| PCT_PF_READS_ALIGNED | The percentage of PF reads that aligned to the reference sequence. PF_READS_ALIGNED / PF_READS |"
	echo "| PF_READS_ALIGNED | The number of PF reads that were aligned to the reference sequence. This includes reads that aligned with low quality (i.e. their alignments are ambiguous). |"
	echo "| PCT_READS_ALIGNED_IN_PAIRS | The percentage of reads whose mate pair was also aligned to the reference. READS_ALIGNED_IN_PAIRS / PF_READS_ALIGNED. |"
	echo "| PF_MISMATCH_RATE | The rate of bases mismatching the reference for all bases aligned to the reference sequence. |"
	echo "| MEAN_READ_LENGTH | The mean read length of the set of reads examined. When looking at the data for a single lane with equal length reads this number is just the read length. When looking at data for merged lanes with differing read lengths this is the mean read length of all reads. |"


	echo
	#the table
	echo "In the table below the output of metrics collection is shown."
	echo

	echo 'tableas=read.table("'${collectMultipleMetricsPrefix}.alignment_summary_metrics'", skip=6, header=TRUE, sep="\t", fill=NA);
	 write.table(subset(tableas,select=c("CATEGORY","PF_READS","PCT_PF_READS_ALIGNED","PF_READS_ALIGNED","PCT_READS_ALIGNED_IN_PAIRS","READS_ALIGNED_IN_PAIRS","PF_MISMATCH_RATE", "MEAN_READ_LENGTH"))
	 ,file=stdout(),sep="|", row.names=FALSE, quote=FALSE);' > ${sampleMarkdownDir}/${sampleName}_alignmetrics.R

	Rscript  ${sampleMarkdownDir}/${sampleName}_alignmetrics.R | perl -wpe 'chomp $_; $_="| ".$_." |\n";if($.==1){print $_; $_ =~  s/[A-Z0-9\"\_]+/\ \-\-\-\ /g;}; '

	rm  ${sampleMarkdownDir}/${sampleName}_alignmetrics.R
)>> ${sampleMarkdown}
################################################################################
##
#

if [ -e ${markDuplicatesMetrics} ] ; then
	(
		echo
		echo "Duplication removal metrics"
		echo "==========================="
		echo
		echo "**metrics definitions**"
		echo
		echo "literal source: http://broadinstitute.github.io/picard/picard-metric-definitions.html"
		echo
		echo "| field | description |"
		echo "| ----- | ----------- |"
		echo "| UNPAIRED_READS_EXAMINED | The number of mapped reads examined which did not have a mapped mate pair, either because the read is unpaired, or the read is paired to an unmapped mate. |"
		echo "| READ_PAIRS_EXAMINED | The number of mapped read pairs examined. |"
		echo "| UNMAPPED_READS | The total number of unmapped reads examined. |"
		echo "| UNPAIRED_READ_DUPLICATES | The number of fragments that were marked as duplicates. |"
		echo "| READ_PAIR_DUPLICATES | The number of read pairs that were marked as duplicates. |"
		echo "| READ_PAIR_OPTICAL_DUPLICATES | The number of read pairs duplicates that were caused by optical duplication. Value is always < READ_PAIR_DUPLICATES, which counts all duplicates regardless of source. |"
		echo "| PERCENT_DUPLICATION | The percentage of mapped sequence that is marked as duplicate. |"
		echo "| ESTIMATED_LIBRARY_SIZE | The estimated number of unique molecules in the library based on PE duplication. |"
		echo

		#the table
		echo "In the table below the output of metrics collection is shown."
		echo
		perl -wne 'BEGIN{my $pr=0;};$pr=0 if($_ =~ m/^\n$/); $pr = 1 if($_ =~ m/LIBRARY/); print $_ if($pr); ' ${markDuplicatesMetrics} > ${markDuplicatesMetrics}.tmp
		#just for logging
		cat ${markDuplicatesMetrics}.tmp >/dev/stderr
		#create markduplicates table for a single sample. Note the recalculation of PCT_PCR_DUPs.
		echo 'tabledup=read.table("'${markDuplicatesMetrics}.tmp'", header=TRUE, sep="\t", fill=NA);
		 colsumstabledup<- colSums(tabledup[,(! is.na(tabledup[1,"ESTIMATED_LIBRARY_SIZE"]) | colnames(x=tabledup)!="ESTIMATED_LIBRARY_SIZE")&colnames(tabledup)!="LIBRARY"&colnames(tabledup)!="PERCENT_DUPLICATION"]);
		 pctDups <- as.numeric(((colsumstabledup[c("UNPAIRED_READ_DUPLICATES")] + colsumstabledup[c("READ_PAIR_DUPLICATES")]*2) / (colsumstabledup[c("UNPAIRED_READS_EXAMINED")] + colsumstabledup[c("READ_PAIRS_EXAMINED")] *2)));
		 colsumstabledup["PERCENT_DUPLICATION"] = pctDups;colsumstabledup= c("Field"= "Value",colsumstabledup);
		#java:PERCENT_DUPLICATION = (UNPAIRED_READ_DUPLICATES + READ_PAIR_DUPLICATES *2) /(double) (UNPAIRED_READS_EXAMINED + READ_PAIRS_EXAMINED *2);
		 write.table(t(colsumstabledup) ,file=stdout(),sep="|", row.names=FALSE, quote=FALSE, col.names=TRUE);' >  ${sampleMarkdownDir}/${sampleName}_dupmetrics.R;
		Rscript  ${sampleMarkdownDir}/${sampleName}_dupmetrics.R | perl -wpe 'chomp $_; $_="| ".$_." |\n";if($.==1){print $_; $_ =~  s/[a-zA-Z0-9\"\_]+/\ \-\-\-\ /g;}; '
		rm   ${sampleMarkdownDir}/${sampleName}_dupmetrics.R
	)>> ${sampleMarkdown}
else
	(
		echo
		echo "Duplication removal metrics"
		echo "==========================="
		echo "No markduplicates performed."
	)>> ${sampleMarkdown}
fi

#the hist
#perl -wne 'BEGIN{my $pr=0;};$pr=0 if($_ =~ m/^\n$/); $pr = 1 if($_ =~ m/BIN\tVALUE/); print $_ if($pr) ' /groups/umcg-oncogenetics/tmp04/projects/BGI3_ALK_8_test/markDuplicates/ALK_8-R.metrics.log >> ${sampleMarkdown}


#>> ${sampleMarkdown}

################################################################################
##
#

if [ ${#reads2FqGz} -ne 0 ]; then
	(
		echo
		echo "Paired end metrics"
		echo "=================="
		echo
		echo "**metrics definitions**"
		echo
		echo "literal source: http://broadinstitute.github.io/picard/picard-metric-definitions.html"
		echo
		echo "| field | description |"
		echo "| ----- | ----------- |"
		echo "| MEDIAN_INSERT_SIZE | The MEDIAN insert size of all paired end reads where both ends mapped to the same chromosome. |"
		echo "| MEDIAN_ABSOLUTE_DEVIATION | The median absolute deviation of the distribution. If the distribution is essentially normal then the standard deviation can be estimated as ~1.4826 * MAD. |"
		echo "| MEAN_INSERT_SIZE | The mean insert size of the "core" of the distribution. Artefactual outliers in the distribution often cause calculation of nonsensical mean and stdev values. To avoid this the distribution is first trimmed to a "core" distribution of +/- N median absolute deviations around the median insert size. By default N=10, but this is configurable. |"
		echo "| PAIR_ORIENTATION | The pair orientation of the reads in this data category. |"
		echo
		echo "Results shown in table below."
		echo
		#${collectMultipleMetricsPrefix}.insert_size_metrics
		perl -wne 'BEGIN{my $pr=0;};$pr=0 if($_ =~ m/^\n$/); $pr = 1 if($_ =~ m/LIBRARY/); print $_ if($pr);' ${collectMultipleMetricsPrefix}.insert_size_metrics > ${collectMultipleMetricsPrefix}.insert_size_metrics.tmp
		#${collectMultipleMetricsPrefix}.insert_size_metrics.tmp

		echo 'tablepe=read.table("'${collectMultipleMetricsPrefix}.insert_size_metrics.tmp'", header=TRUE, sep="\t", fill=NA);
		 write.table(subset(tablepe,select=c("MEDIAN_INSERT_SIZE","MEDIAN_ABSOLUTE_DEVIATION","MEAN_INSERT_SIZE","PAIR_ORIENTATION"))
		 ,file=stdout(),sep="|", row.names=FALSE, quote=FALSE);'> ${sampleMarkdownDir}/${sampleName}_pemetrics.R;

		Rscript ${sampleMarkdownDir}/${sampleName}_pemetrics.R | perl -wpe 'chomp $_; $_="| ".$_." |\n";if($.==1){print $_; $_ =~  s/[A-Z0-9\"\_]+/\ \-\-\-\ /g;}; '
	) >> ${sampleMarkdown}
		rm  ${sampleMarkdownDir}/${sampleName}_pemetrics.R
else
	(
		echo "Paired end metrics"
		echo "=================="
		echo
		echo "This is single end read data. So this was not performed."
	)  >>  ${sampleMarkdown}
fi

################################################################################
##
#
	(
		echo
		echo "Notes"
		echo "====="

		echo "This report was generated with this [source](https://github.com/mmterpstra/molgenis-c5-TumorNormal).
 This is used for research and may contain errors or typoos. So if you encounter
 issues please report them to the github or by mailing the correct people. Also
 do not be afraid to contact if you have suggestions and improvements."
	) >> ${sampleMarkdown}

#yo, i heard you like html templates so ...

htmlTemplate='<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>

	<title>#!title#</title>
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/uikit/2.24.2/css/uikit.min.css" />
	<script src="https://cdnjs.cloudflare.com/ajax/libs/uikit/2.24.2/js/uikit.min.js"></script>
	<script src="//code.jquery.com/jquery-1.11.3.min.js"></script>
	<script src="//code.jquery.com/jquery-migrate-1.2.1.min.js"></script>

#!r_highlight#

#!mathjax#

<style type="text/css">
#!markdown_css#
</style>

#!header#

</head>

<body>
#!html_output#
</body>

</html>'
htmlTemplateFile=$(mktemp)
echo $htmlTemplate > $htmlTemplateFile

echo  'markdown::markdownToHTML(file="'${sampleMarkdown}'", template="'$htmlTemplateFile'", output="'${sampleMarkdown}.html'")' > ${sampleMarkdownDir}/${sampleName}_markdownToHtml.R

Rscript ${sampleMarkdownDir}/${sampleName}_markdownToHtml.R

rm -v ${sampleMarkdownDir}/${sampleName}_markdownToHtml.R

rm $htmlTemplateFile

putFile  ${sampleMarkdown}
putFile  ${sampleMarkdown}.html

echo "## "$(date)" ##  $0 Done "
