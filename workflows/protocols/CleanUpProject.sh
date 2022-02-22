#MOLGENIS walltime=23:59:00 mem=5gb ppn=1

#string project

#string projectDir
#string bqsrDir
#string indelRealignmentDir
#string splitAndTrimDir
#string markDuplicatesDir
#string htseqDir
#string htseqDupsDir
#string sampleMarkdownDir
#string projectMarkdown
#string calculateHsMetricsDir
#string collectMultipleMetricsDir
#string nugeneProbeMetricsDir
#list varscanDir,snvVcf,indelMnpVcf
#string fastqcDir
#string xlsxDir
#string splitTableDir
#string htseqDir
#string htseqDupsDir
#string qdnaseqDir
#string fusioncatcherDir
#string projectSampleSheet
#string multiQcHtml
#string convadingDir

set -x -e -o pipefail

archiveDir="$(dirname "${projectDir}")"/"$(basename "${projectDir}")""_archive"
zipbase='zip -n bam:xlsx:cram -ru '"${archiveDir}"'/'"${project}"'.zip '

alloutputsexist \
	"$archiveDir" \
	"$archiveDir"/${project}.zip" \


#(
	cd "$(dirname "${projectDir}")"
	
	for dir in "${calculateHsMetricsDir}" "${collectMultipleMetricsDir}" "${fastqcDir}" "${xlsxDir}" "${splitTableDir}" "${convadingDir}"; do
		if [ -n "$(ls -A $dir/*)" ]; then
	               	$zipbase $(echo "$dir/*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		fi
	done
	
	for file in $(ls "${projectSampleSheet}" "${snvVcf[@]}" "${indelMnpVcf[@]}" "${projectMarkdown}.html"  "${multiQcHtml}" | sort -u); do
		if [ -n "$(ls -A $file*)" ]; then
	               	$zipbase $(echo "$file*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		fi
	done

	#varscan results
	if [ -n "$(ls -A ${projectDir}/varscan.*)" ]; then
		for i in ${projectDir}/varscan.*; do
			$zipbase $(echo "${i}/*.pdf ${i}/*.seg ${i}/*.table" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		done
	fi

	#ichorcna results
	if [ -n "$(ls -A ${projectDir}/ichorCNA/*/*.pdf)" ]; then
		for i in ${projectDir}/ichorCNA/*; do
			$zipbase $(echo "${i}" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		done
	fi
	#cnvkit results
	if [ -n "$(ls -A ${projectDir}/cnv.*)" ]; then
		for i in ${projectDir}/cnv.*; do
			$zipbase $(echo "${i}/*.pdf ${i}/*.cn[rsn]" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		done
	fi
	
	#qdnaseq
	if [ -n "$(ls -A ${projectDir}/qdnaseq)" ]; then
		for i in ${projectDir}/qdnaseq*; do
			$zipbase $(echo "${i}/*.pdf ${i}/*.cn[rsn]" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		done
	fi
	
	#add csvs in main dir to project
	dir="${projectDir}"'/*'
	if [ -n "$(ls -A ${dir}/*.csv)" ]; then
		$zipbase $(echo "${dir}/*.csv" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	if [ -n "$(ls -A ${dir}/*list)" ]; then
		$zipbase $(echo "${projectDir}/*list" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	
	if [ -n "$(ls -A ${dir}/*list)" ]; then
		$zipbase $(echo "${projectDir}/*list" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	
	#qc html by sample
	if [ -n "$(ls -A ${sampleMarkdownDir}/*.html)" ]; then
		$zipbase $(echo "${sampleMarkdownDir}/*.html" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	
	#rna seq output of htseq-count
	if [ -e  "${htseqDir}" ]; then
		$zipbase $(echo "${htseqDir}/*.tsv" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	#rna seq output of htseq-count with dups?
	if [ -e  "${htseqDupsDir}" ]; then
	        $zipbase $(echo "${htseqDupsDir}/*.tsv" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	#rna seq output of fusions of fusioncather
	if [ -e "${fusioncatcherDir}" ]; then
		$zipbase $(echo "${fusioncatcherDir}/*/final-list_candidate-fusion-genes.txt" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		$zipbase $(echo "${fusioncatcherDir}/*/final-list_candidate-fusion-genes.xlsx" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	
	#for markduplicates results log
	if [  -e "${markDuplicatesDir}" ]; then
	        for dir in  "${markDuplicatesDir}" ; do
	                if [ -n "$(ls -A $dir/*.log)" ]; then
	                        $zipbase  $(echo "$dir/*.log" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	                fi
	        done
	
	fi
	
	#nugene probeMetrics output
	if [ -e "${nugeneProbeMetricsDir}" ]; then
		$zipbase $(echo "${nugeneProbeMetricsDir}/*.tsv" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		#$zipbase $(echo "${nugeneProbeMetricsDir}/*.xlsx" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
	

	###############################
	#Stuff below here goes into output without zipping
	
	#tar -zcf ${projectDir}/${project}_nobam.tar.gz $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
	#zip -r ${projectDir}/${project}_nobam.zip $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
	#cp "${project}"'.zip' "${project}"'_nobam.zip'
	#md5sum ${project}_nobam.zip > ${project}_nobam.zip.md5
	
	if [ -e "${bqsrDir}" ]  ; then
		for dir in  "${bqsrDir}" ; do
			if [ -n "$(ls -A $dir/*)" ]; then
				cp -r "$(dirname "$dir")""/""$(basename "$dir")" "${archiveDir}/"
			fi
		done
	
	#control for workflows skipping bqsr 
	elif [  -e "${indelRealignmentDir}" ]; then
	        for dir in  "${indelRealignmentDir}" ; do
	                if [ -n "$(ls -A $dir/*)" ]; then
	                        cp -r "$(dirname "$dir")""/""$(basename "$dir")" "${archiveDir}/"
	                fi
	        done
	
	fi
	
	#control for rna seq spliced alignments in markduplicates dir
	if [  -e "${markDuplicatesDir}" ] && [ -e "${splitAndTrimDir}" ]; then
		for dir in  "${markDuplicatesDir}" ; do
	                if [ -n "$(ls -A $dir/*)" ]; then
				cp -r "$(dirname "$dir")""/""$(basename "$dir")" "${archiveDir}/"
	                fi
	        done
	
	fi
	
	#cd "${projectDir}"
	md5sum ${project}.zip > ${project}.zip.md5
	
	for i in $(ls ${projectDir}/*/ -d| grep -v jobs ); do 
		echo $i
		#sleep 10s;
		#rm -rv $i;
	done
	
	putFile "$archiveDir"
	putFile "$archiveDir"/${project}.zip" 
#)

echo "## "$(date)" ##  $0 Done "

