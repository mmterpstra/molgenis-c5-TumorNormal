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
#string lnFq1Name
#string lnFq2Name
#string lnFq3Name

echo -e "test ${reads1FqGz} ${reads2FqGz} 1: $(basename ${reads1FqGz} .gz)${fastqcZipExt} \n2: $(basename ${reads2FqGz} .gz)${fastqcZipExt} "

${stage} ${fastqcMod}
${checkStage}

set -x -e -o pipefail

echo "## "$(date)" ##  $0 Started "

# cd ${fastqcBasename}
#                        unzip -u -o ${fastqcBasename}/$(echo -n $fq | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')"_fastqc.zip" \*/fastqc_data.txt -d ${fastqcBasename}
#                        readnumberfastq=$(grep 'Total Sequences'  ${fastqcBasename}//$(echo -n $fq | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')"_fastqc"/fastqc_data.txt | cut  -f2)


if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	
	echo "## "$(date)" Started single end fastqc"
	alloutputsexist \
         ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} \
	 ${singleEndfastqcZip}

	getFile ${reads1FqGz}
	
	mkdir -p ${fastqcDir}  ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/
	cd ${fastqcDir}
	
	if [ "${reads1FqGz}" != "${lnFq1Name}" ] && [ ! -e "${lnFq1Name}" ]; then 
	
		cp -v ${reads1FqGz} ${lnFq1Name}

	fi
	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract ${reads1FqGz} --outdir ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/
	fastqc --noextract ${lnFq1Name}
	echo
	
	if [ $(zcat ${reads1FqGz} | wc -l) -eq 0 ]; then
		mkdir -p ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz}| perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc"/ 
		echo -e "Total Sequences\t1\n" > ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz}| perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc"/fastqc_data.txt
		rm -v ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz}| perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt}
		zip -ru ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} \
			${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz}| perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc"/fastqc_data.txt
	else 
		echo "## INFO ## More then 0 reads present."
	fi
	
	cp -v ${fastqcDir}/$(basename ${singleEndfastqcZip} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} ${singleEndfastqcZip}

	
	##################################################################
	
	cd $OLDPWD
	
	rm -v ${lnFq1Name}
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
	
        if [ "${reads1FqGz}" != "${lnFq1Name}" ] && [ ! -e "${lnFq1Name}" ]; then

                cp -v ${reads1FqGz} ${lnFq1Name}

        fi
        if [ "${reads2FqGz}" != "${lnFq2Name}" ] && [ ! -e "${lnFq2Name}" ]; then

                cp -v ${reads2FqGz} ${lnFq2Name}

        fi


	##################################################################
	echo
	echo "## "$(date)" reads1FqGz"
	fastqc --noextract ${reads1FqGz} --outdir ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)
	fastqc --noextract ${lnFq1Name}
	
	if [ $(zcat ${reads1FqGz} | wc -l) -eq 0 ]; then
		mkdir -p $(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc"
                echo -e "Total Sequences\t0\n" > $(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc"/fastqc_data.txt
		rm -v ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt}
                zip -ru ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} fastqc_data.txt
        else
            	echo "## INFO ## More then 0 reads present."
        fi

	
	cp -v ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')${fastqcZipExt} ${pairedEndfastqcZip1}
	echo
	echo "## "$(date)" reads2FqGz"
	fastqc --noextract ${reads2FqGz} --outdir ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)
	fastqc --noextract ${lnFq2Name}
	echo
	
	if [ $(zcat ${reads2FqGz} | wc -l) -eq 0 ]; then
                mkdir -p $(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc" 
                echo -e "Total Sequences\t0\n" > $(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc"/fastqc_data.txt
		rm -v ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt}
                zip -ru ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} \
			$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )"_fastqc"/fastqc_data.txt
        else
            	echo "## INFO ## More then 0 reads present."
        fi
	
	
	cp -v ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g' )${fastqcZipExt} ${pairedEndfastqcZip2}

	##################################################################
	cd $OLDPWD
	
	rm -v ${lnFq1Name}
	rm -v ${lnFq2Name}
	
	putFile ${pairedEndfastqcZip1}
	putFile ${pairedEndfastqcZip2}

	putFile ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)/$(echo -n ${reads1FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')${fastqcZipExt}
	putFile ${fastqcDir}/$(basename ${pairedEndfastqcZip2} .zip)/$(echo -n ${reads2FqGz} | perl -wpe 's!.*/|\.fq\.gz|\.fastq\.gz|\.gz!!g')${fastqcZipExt}
fi

if [ ${#reads3FqGz} -ne 0 ] && [ ${reads1FqGz} == ${reads1FqGzOriginal} ] ; then
	getFile ${reads3FqGz}
	cp -v ${reads3FqGz} ${lnFq3Name}
	
	fastqc --noextract ${reads3FqGz} --outdir ${fastqcDir}/$(basename ${pairedEndfastqcZip1} .zip)
	fastqc --noextract ${lnFq3Name}
	
	rm -v ${lnFq3Name}
	
fi
echo "## "$(date)" ##  $0 Done "
