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
#string calculateHsMetricsDir
#string collectMultipleMetricsDir
#list varscanDir,snvVcf,indelMnpVcf
#string fastqcDir
#string xlsxDir
#string htseqDir
#

set -e
set -x

alloutputsexist \
"$(dirname "${projectDir}")/${project}_nobam.zip" \
"$(dirname "${projectDir}")/${project}.zip" \
 


cd "$(dirname "${projectDir}")"

#files=""
zipbase='zip -n bam:xlsx:cram -ru '${project}'.zip '
olddir=$(pwd)
cd "$(dirname "${projectDir}")"


for dir in "${calculateHsMetricsDir}" "${collectMultipleMetricsDir}" "${fastqcDir}" "${xlsxDir}"; do
	if [ -n "$(ls -A $dir/*)" ]; then
               	$zipbase $(echo "$dir/*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
done

for file in $(ls  "${snvVcf[@]}*" "${indelMnpVcf[@]}" | sort -u); do
	if [ -n "$(ls -A $file*)" ]; then
               	$zipbase $(echo "$file*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
	fi
done

dir="${projectDir}"'/*'
if [ -n "$(ls -A ${dir}/*.seg)" ]; then
	$zipbase $(echo "${varscanDir}/*.seg" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi
if [ -n "$(ls -A ${dir}/*.called)" ]; then
	$zipbase $(echo "${varscanDir}/*.called" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi
if [ -n "$(ls -A ${dir}/*.called.gc)" ]; then
	$zipbase $(echo "${varscanDir}/*.called.gc" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi
if [ -n "$(ls -A ${dir}/*.called.homdels)" ]; then
	$zipbase $(echo "${varscanDir}/*.called.homdels" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi
if [ -n "$(ls -A ${dir}/*.pdf)" ]; then
        $zipbase $(echo "${varscanDir}/*.pdf" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi
if [ -n "$(ls -A ${dir}/multi/*)" ]; then
        $zipbase $(echo "${varscanDir}/multi/*.[tps][esd][gvf]" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi


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
#	if [ -n "$(ls -A ${dir}*)" ]; then
#		$zipbase $(echo "${snvVcf}*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
#	fi
	
#	if [ -n "$(ls -A ${dir}*)" ]; then
#		$zipbase $(echo "${indelMnpVcf}*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
#	fi
if [ -n "$(ls -A ${sampleMarkdownDir}/*.html)" ]; then
	$zipbase $(echo "${sampleMarkdownDir}/*.html" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi

if [ -e  "${htseqDir}" ]; then 
	$zipbase $(echo "${htseqDir}/*.tsv" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
fi


#tar -zcf ${projectDir}/${project}_nobam.tar.gz $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
#zip -r ${projectDir}/${project}_nobam.zip $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
cp "${project}"'.zip' "${project}"'_nobam.zip'
md5sum ${project}_nobam.zip > ${project}_nobam.zip.md5

if [ -e "${bqsrDir}" ]  ; then
	for dir in  "${bqsrDir}" ; do
		if [ -n "$(ls -A $dir/*)" ]; then
			$zipbase $(echo "$dir/*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
		fi
	done

elif [  -e "${indelRealignmentDir}" ] ]; then
        for dir in  "${indelRealignmentDir}" ; do
                if [ -n "$(ls -A $dir/*)" ]; then
                        $zipbase $(echo "$dir/*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
                fi
        done

fi


if [  -e "${markDuplicatesDir}" ] && [ -e "${splitAndTrimDir}" ]; then
	for dir in  "${markDuplicatesDir}" ; do
                if [ -n "$(ls -A $dir/*)" ]; then
                        $zipbase  $(echo "$dir/*" | perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g;s!/+!/!g')
                fi
        done

fi

#olddir=$(pwd)
#cd "$(dirname "${projectDir}")"

#tar -zcf ${projectDir}/${project}.tar.gz $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
#zip -r ${projectDir}/${project}.zip $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')

#cd "${projectDir}"
md5sum ${project}.zip > ${project}.zip.md5
#cd $olddir

for i in $(ls ${projectDir}/*/ -d| grep -v jobs ); do 
	echo $i
	#sleep 10s;
	#rm -rv $i;
done

putFile "$(dirname "${projectDir}")/${project}_nobam.zip" 
putFile "$(dirname "${projectDir}")/${project}.zip" 


