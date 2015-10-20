#MOLGENIS walltime=23:59:00 mem=10mb ppn=1
#string projectDir
#string project
#string bqsrDir
#string calculateHsMetricsDir
#string collectMultipleMetricsDir
#list varscanDir,snvVcf,indelMnpVcf
#string fastqcDir
#string xlsxDir

#
set -e
set -x

files=""

for dir in "${calculateHsMetricsDir}" "${collectMultipleMetricsDir}" "${collectMultipleMetricsDir}" "${fastqcDir}" "${xlsxDir}"; do
	if [ -n "$(ls -A $dir/*)" ]; then
		files="$files $dir/* "
	fi
done
for file in  "${snvVcf[@]}*" "indelMnpVcf" ; do
	if [ -n "$(ls -A $file*)" ]; then
		files="$files $file* "
	fi
done

for dir in  "${varscanDir[@]}*" ; do
	if [ -n "$(ls -A ${dir}/*.seg)" ]; then
			files="$files ${varscanDir}/*.seg"
	fi
	if [ -n "$(ls -A ${dir}/*.called)" ]; then
			files="$files ${varscanDir}/*.called"
	fi
	if [ -n "$(ls -A ${dir}/*.called.gc)" ]; then
			files="$files ${varscanDir}/*.called.gc"
	fi
	if [ -n "$(ls -A ${dir}/*.called.homdels)" ]; then
			files="$files ${varscanDir}/*.called.homdels"
	fi


	if [ -n "$(ls -A ${dir}/*.csv)" ]; then
			files="$files ${projectDir}/*.csv"
	fi
	if [ -n "$(ls -A ${dir}/*list)" ]; then
			files="$files ${projectDir}/*list"
	fi
	
	if [ -n "$(ls -A ${dir}/*list)" ]; then
			files="$files ${projectDir}/*list"
	fi
	if [ -n "$(ls -A ${dir}*)" ]; then
			files="$files ${snvVcf}*"
	fi
	
	if [ -n "$(ls -A ${dir}*)" ]; then
			files="$files ${indelMnpVcf}*"
	fi
done

olddir=$(pwd)
cd "$(dirname "${projectDir}")"


#tar -zcf ${projectDir}/${project}_nobam.tar.gz $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
zip -r ${projectDir}/${project}_nobam.zip $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
cd "${projectDir}"
md5sum ${project}_nobam.zip > ${project}_nobam.zip.md5
cd $olddir

for dir in  "${bqsrDir}" ; do
	if [ -n "$(ls -A $dir/*)" ]; then
		files="$files $dir/* "
	fi
done

olddir=$(pwd)
cd "$(dirname "${projectDir}")"

#tar -zcf ${projectDir}/${project}.tar.gz $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')
zip -r ${projectDir}/${project}.zip $(echo $files| perl -wpe 's!'"$(dirname "${projectDir}")"'/*!!g' | perl -wpe 's!/+!/!g')

cd "${projectDir}"
md5sum ${project}.zip > ${project}.zip.md5
cd $olddir

for i in $(ls ${projectDir}/*/ -d| grep -v jobs ); do 
	echo $i
	sleep 10s;
	#rm -rv $i;
done

#tar
#tar -zcf project.tar.gz\
#$project/baseQualityScoreRecalibration/* \
#$project/HsMetrics/* \
#$project/multipleMetrics/* \
#$project/varscan*/*.seg \
#$project/varscan*/*.called \
#$project/varscan*/*.called.gc \
#$project/varscan*/*.called.homdels \
#$project/varscan*/*.pdf \
#$project/fastqc/* \
#$project/*csv \
#$project/*list 
#rm


