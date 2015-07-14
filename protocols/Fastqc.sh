#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string fastqcMod
#string WORKDIR
#string projectDir
#string fastqcDir
#string fastqcZipExt
#string reads1FqGz
#string reads2FqGz
#string sampleName
#string singleEndfastqcZip
#string pairedEndfastqcZip1
#string pairedEndfastqcZip2

echo -e "test ${reads1FqGz} ${reads2FqGz} 1: $(basename ${reads1FqGz} .gz)${fastqcZipExt} \n2: $(basename ${reads2FqGz} .gz)${fastqcZipExt} "

${stage} ${fastqcMod}
${checkStage}

set -x
set -e

echo "## "$(date)" ##  $0 Started "

if [ ${#reads2FqGz} -eq 0 ]; then
	
	echo "## "$(date)" Started single end fastqc"
	alloutputsexist \
	 ${fastqcDir}/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.gz!!g' )${fastqcZipExt} \
	 ${singleEndfastqcZip}

	getFile ${reads1FqGz}
	
	mkdir -p ${fastqcDir}
	cd ${fastqcDir}
	
	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract ${reads1FqGz} --outdir ${fastqcDir}
	echo
	cp -v ${fastqcDir}/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.gz!!g' )${fastqcZipExt} ${singleEndfastqcZip}

	##################################################################
	
	cd $OLDPWD

	putFile ${fastqcDir}/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.gz!!g' )${fastqcZipExt}
	putFile ${singleEndfastqcZip}

else
	echo "## "$(date)" Started paired end fastqc"
	
	alloutputsexist \
	 ${fastqcDir}/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.gz!!g' )${fastqcZipExt} \
	 ${fastqcDir}/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.gz!!g' )${fastqcZipExt} \
	 ${pairedEndfastqcZip1} \
	 ${pairedEndfastqcZip2}

	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
	
	mkdir -p ${fastqcDir}
	cd ${fastqcDir}
	
	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract ${reads1FqGz} --outdir ${fastqcDir}
	
	cp -v ${fastqcDir}/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fastq\.gz|\.fq\.gz|\.fq|\.fastq!!g')${fastqcZipExt} ${pairedEndfastqcZip1}
	echo
	echo "## "$(date)" reads2FqGz"
	fastqc --noextract ${reads2FqGz} --outdir ${fastqcDir}
	echo
	cp -v ${fastqcDir}/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.gz!!g' )${fastqcZipExt} ${pairedEndfastqcZip2}

	##################################################################
	cd $OLDPWD
		
	putFile ${fastqcDir}/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fastq\.gz|\.fq\.gz|\.fq|\.fastq!!g')${fastqcZipExt}
	putFile ${fastqcDir}/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.gz!!g' )${fastqcZipExt}
	putFile ${pairedEndfastqcZip1}
	putFile ${pairedEndfastqcZip2}
	
fi

echo "## "$(date)" ##  $0 Done "
