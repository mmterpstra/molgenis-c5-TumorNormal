#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project
#string projectDir

#string RMod
#string RmarkMod
#string stage
#string checkStage

#list sampleMarkdown
#string projectMarkdown
#string dcovTsv

alloutputsexist \
 ${projectMarkdown} \
 ${projectMarkdown}.html \

echo "## "$(date)" Start $0"

#load modules
${stage} ${RmarkMod}

${checkStage}

set -x
set -e

#get samplemarkdown
mds=($(printf '%s\n' "${sampleMarkdown[@]}" | sort -u ))

mdlist=

for md in "${mds[@]}"; do
	getFile $md
	if [ -s $md ]; then
		echo "added $md to merge list";
		mdlist=("${mdlist[@]}" "$md")
	fi
done


#main and collect data
(
	echo "# ${project} Project info"
	echo
	echo "This contains the ${project} project info of all the samples in the project. This contains the following steps:"
	echo
	echo " - Fastq metrics"
	echo " - Alignment metrics"
	echo " - Duplicate metrics"
	echo " - Hybrid selection (abbr. HS) metrics"

) >  ${projectMarkdown}



#fastq table

(
        echo
	echo "## Fastq metrics"
        echo
        echo "Result table of the fastq metrics for all samples"
        echo
	#clean this up as future work
        HEADER=$(echo -en "|\tsamplename\t|\tReads raw\t|\tReads clean\t|\tBases clean\t|\tClean bases Q20\t|\tClean bases Q30\t|")
	#grep -A 1 "$HEADER" ${mdlist[1]}

        echo $HEADER
	echo -e "|\t---\t|\t---\t|\t---\t|\t---\t|\t---\t|\t---\t|"

        for md in "${mdlist[@]}"; do
               	if [ -s "$md" ] ; then
			#samplename is already present
			#SAMPLENAME=$(perl -wne 'print $1 if /Sample Info on:(.*)/' $md)
	               	#grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1
			grep -A 2 "$HEADER" "$md" | tail -n 1
		fi
        done
) >>  ${projectMarkdown}

#alignment metrics

(
        echo
        echo "## Alignment metrics"
        echo
	echo "Result table of the alignment for all samples"
        echo
        HEADER='| CATEGORY|PF_READS|PCT_PF_READS_ALIGNED|PF_READS_ALIGNED|PCT_READS_ALIGNED_IN_PAIRS|READS_ALIGNED_IN_PAIRS|PF_MISMATCH_RATE|MEAN_READ_LENGTH |'
        grep -A 1 "$HEADER" ${mdlist[1]} | perl -wpe 's/^\|.*CATEGORY/\| SAMPLE \| CATEGORY/;s/^\|  --- /\|  --- \|  --- /;'
        for md in "${mdlist[@]}"; do
		if [ -s "$md" ] ; then
			SAMPLENAME=$(perl -wne 'print $1 if /Sample Info on:(.*)/' $md)
                	#if [[ $(grep -A 2 "$HEADER" /scratch/umcg-mterpstra/projects/WES_novogene_path_P1_3/md/WES_novogene_path_P1_3.T11_21822_I.md | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1) =~ "FIRST_OF_PAIR" ]]; then grep -A 4 "$HEADER" /scratch/umcg-mterpstra/projects/WES_novogene_path_P1_3/md/WES_novogene_path_P1_3.T11_21822_I.md | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 3; else grep -A 2 "$HEADER" /scratch/umcg-mterpstra/projects/WES_novogene_path_P1_3/md/WES_novogene_path_P1_3.T11_21822_I.md | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1;fi
			#grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1
			if [[ $(grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1) =~ "FIRST_OF_PAIR" ]]; then 
                       	        #pe
                                grep -A 4 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 3
                        else
                                #se
                                grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1
                        fi
		fi
        done
) >>  ${projectMarkdown}


#markduplicates

(
        echo
        echo "## Duplicate metrics"
        echo
	#header differs between single end and paired end so first use the headerbase to grep the file do determine the real header
	#picard 1.140 header
	#HEADERBASE='| Field|UNPAIRED_READS_EXAMINED|READ_PAIRS_EXAMINED|UNMAPPED_READS|UNPAIRED_READ_DUPLICATES|READ_PAIR_DUPLICATES|READ_PAIR_OPTICAL_DUPLICATES'
	#picard 2.10 header
	HEADERBASE='| Field|UNPAIRED_READS_EXAMINED|READ_PAIRS_EXAMINED|SECONDARY_OR_SUPPLEMENTARY_RDS|UNMAPPED_READS|UNPAIRED_READ_DUPLICATES'

        HEADER="$(grep -A 1 "$HEADERBASE" ${mdlist[1]} | head -1)"
	if [ ! -z "$HEADER" ] ; then
		echo "Result table of the Duplicates for all samples"
	        echo

		grep -A 1 "$HEADER" ${mdlist[1]} | perl -wpe 's/^\|.*Field/\| SAMPLE \| FIELD/;s/^\|  --- /\|  --- \|  --- /;'
        	for md in "${mdlist[@]}"; do
        		if [ -s "$md" ] ; then
                        	SAMPLENAME=$(perl -wne 'print $1 if /Sample Info on:(.*)/' $md)
				grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1
               		fi
        	done
	else
		echo "No Duplicate metrics found."
	fi
) >>  ${projectMarkdown}

#gatkDepthOfCoverage
#dcovTsv}".sample_summary
(
        echo
	echo "## Depth of Coverage Metrics"
        echo
	echo "Result table below for inspection at different coverages. Similar to Hybrid selection metrics."
	echo
	
	grep -v 'Total' "${dcovTsv}".sample_summary | perl -wpe 's/^/| /;s/$/\t |/;s/\t/\t | /g; if($. == 1){print; s/[^\s|]/-/g;}'

) >>  ${projectMarkdown}

#pemetrics?


#hsmetrics
(
	echo
	echo "## Hybrid selection metrics"
	echo

	echo "Result table of the hybrid selection for all samples."
	echo
	HEADER='| SAMPLE|TARGET_TERRITORY|PF_UQ_READS_ALIGNED|PF_UQ_BASES_ALIGNED|ON_TARGET_BASES|PCT_USABLE_BASES_ON_TARGET|MEAN_TARGET_COVERAGE|PCT_TARGET_BASES_2X|PCT_TARGET_BASES_10X|PCT_TARGET_BASES_20X|PCT_TARGET_BASES_30X|PCT_TARGET_BASES_40X|PCT_TARGET_BASES_50X|PCT_TARGET_BASES_100X |'
	grep -A 1 "$HEADER" ${mdlist[1]}
	for md in "${mdlist[@]}"; do
		if [ -s "$md" ] ; then
			grep -A 2 "$HEADER" "$md" | tail -n 1
		fi
	done
) >>  ${projectMarkdown}
#vcf metrics? entincity? gender? HLA type? CGH metrics?

#version
(	echo
	cat $(pwd)/../generation.log
)>> ${projectMarkdown}

#notes
(
	echo
	echo "Notes"
	echo "====="
	echo
	echo "This report was generated with the source present at the following
 github repo: [github.com/mmterpstra/molgenis-c5-TumorNormal](https://github.com/mmterpstra/molgenis-c5-TumorNormal).
 This is used for research and may contain errors or typoos. So if you encounter
 issues please report them to the github or by mailing the correct people. Also
 do not be afraid to contact if you have suggestions and improvements."
) >> ${projectMarkdown}

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

echo  'markdown::markdownToHTML(file="'${projectMarkdown}'", template="'$htmlTemplateFile'", output="'${projectMarkdown}.html'")' > ${projectMarkdown}.markdownToHtml.R

Rscript ${projectMarkdown}.markdownToHtml.R

rm -v ${projectMarkdown}.markdownToHtml.R

rm -v $htmlTemplateFile

putFile  ${projectMarkdown}
putFile  ${projectMarkdown}.html

echo "## "$(date)" ##  $0 Done "

cat ${projectMarkdown}
