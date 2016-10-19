#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project
#string projectDir

#string RMod
#string RmarkMod
#string stage
#string checkStage

#list sampleMarkdown
#string projectMarkdown

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
			SAMPLENAME=$(perl -wne 'print $1 if /Sample Info on:(.*)/' $md)
	               	grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1
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
                	grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1
		fi
        done
) >>  ${projectMarkdown}


#markduplicates

(
        echo
        echo "## Duplicate metrics"
        echo
        echo "Result table of the Duplicates for all samples"
        echo
        HEADER='| Field|UNPAIRED_READS_EXAMINED|READ_PAIRS_EXAMINED|UNMAPPED_READS|UNPAIRED_READ_DUPLICATES|READ_PAIR_DUPLICATES|READ_PAIR_OPTICAL_DUPLICATES|PERCENT_DUPLICATION |'
        grep -A 1 "$HEADER" ${mdlist[1]} | perl -wpe 's/^\|.*CATEGORY/\| SAMPLE \| CATEGORY/;s/^\|  --- /\|  --- \|  --- /;'
        for md in "${mdlist[@]}"; do
                if [ -s "$md" ] ; then
                        SAMPLENAME=$(perl -wne 'print $1 if /Sample Info on:(.*)/' $md)
                        grep -A 2 "$HEADER" "$md" | perl -wpe 's/^/\| '$SAMPLENAME' /;'|  tail -n 1 
               	fi
        done
) >>  ${projectMarkdown}



#hsmetrics

(
	echo
	echo "## Hybrid selection metrics"
	echo
	echo "Result table of the hybrid selection for all samples"
	echo
	HEADER='| SAMPLE|TARGET_TERRITORY|PF_UQ_READS_ALIGNED|PF_UQ_BASES_ALIGNED|ON_TARGET_BASES|PCT_USABLE_BASES_ON_TARGET|MEAN_TARGET_COVERAGE|PCT_TARGET_BASES_2X|PCT_TARGET_BASES_10X|PCT_TARGET_BASES_20X|PCT_TARGET_BASES_30X|PCT_TARGET_BASES_40X|PCT_TARGET_BASES_50X|PCT_TARGET_BASES_100X |'
	grep -A 1 "$HEADER" ${mdlist[1]}
	for md in "${mdlist[@]}"; do
		if [ -s "$md" ] ; then
			grep -A 2 "$HEADER" "$md" | tail -n 1
		fi
	done
) >>  ${projectMarkdown}

cat ${projectMarkdown}
mv  ${projectMarkdown} ${projectMarkdown}.tmp
#vcf metrics??


putFile ${projectMarkdown}
echo "## "$(date)" ##  $0 Done "
