#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string fastqcMod
#string projectDir
#string fastqcDir
#string fastqcZipExt
#string reads1FqGz
#string reads2FqGz
#string reads3FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal
#string sampleName
#string singleEndfastqcZip
#string pairedEndfastqcZip1
#string pairedEndfastqcZip2

echo -e "test ${reads1FqGz} ${reads2FqGz} 1: $(basename ${reads1FqGz} .gz)${fastqcZipExt} \n2: $(basename ${reads2FqGz} .gz)${fastqcZipExt} "

${stage} ${fastqcMod}
${checkStage}

set -x -e -o pipefail

echo "## "$(date)" ##  $0 Started "

if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	
	echo "## "$(date)" Started single end fastqc"
	alloutputsexist \
         ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} \
	 ${singleEndfastqcZip}

	getFile ${reads1FqGz}
	
	mkdir -p ${fastqcDir}  ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/
	cd ${fastqcDir}
	
	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract ${reads1FqGz} --outdir ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/
	echo
	cp -v ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} ${singleEndfastqcZip}

	##################################################################
	
	cd $OLDPWD

	putFile ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt}
	putFile ${singleEndfastqcZip}

else
	echo "## "$(date)" Started paired end fastqc"
	
	alloutputsexist \
	 ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} \
	 ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} \
	 ${pairedEndfastqcZip1} \
	 ${pairedEndfastqcZip2}

	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
	
	mkdir -p ${fastqcDir} ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip) ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)
	cd ${fastqcDir}
	
	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract ${reads1FqGz} --outdir ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)
	
	cp -v ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')${fastqcZipExt} ${pairedEndfastqcZip1}
	echo
	echo "## "$(date)" reads2FqGz"
	fastqc --noextract ${reads2FqGz} --outdir ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)
	echo
	cp -v ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} ${pairedEndfastqcZip2}

	##################################################################
	cd $OLDPWD
	
	putFile ${pairedEndfastqcZip1}
	putFile ${pairedEndfastqcZip2}

	putFile ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')${fastqcZipExt}
	putFile ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')${fastqcZipExt}
fi

if [ ${#reads3FqGz} -ne 0 ] && [ ${reads1FqGz} == ${reads1FqGzOriginal} ] ; then
	fastqc --noextract ${reads3FqGz} --outdir ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)
fi
echo "## "$(date)" ##  $0 Done "
