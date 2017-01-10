#MOLGENIS nodes=1 ppn=1 mem=12gb walltime=10:00:00

#string project

#Parameter mapping 

#string stage
#string checkStage
#string bbmapMod
#string digiRgMod
#string pipelineUtilMod
#string hisat2Mod
#string probeFa
#string onekgGenomeFastaIdxBase 
#string hisat2SpliceKnownTxt
#string probeBed
#string nugeneFastqDir 

#string reads1FqGz
#string reads2FqGz
#string reads3FqGz

#string nugeneReads1FqGz
#string nugeneReads2FqGz


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
#alloutputsexist \
#	${nugeneReads1FqGz}
 
#getFile functions

getFile ${reads1FqGz}
getFile ${probeFa}

#Load modules
${stage} ${bbmapMod}
${stage} ${digiRgMod}
${stage} ${pipelineUtilMod}
${stage} ${hisat2Mod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${nugeneFastqDir}



if [ ${#reads2FqGz} -eq 0 ]; then
	getFile ${reads1FqGz}
	readspec=" -U ${reads1FqGz} "
else
	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
	readspec=" -1 ${reads1FqGz} -2 ${reads2FqGz} "
fi

if [ ${#reads3FqGz} -eq 0 ]; then
    	TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
        echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1
        TMPFASTQ2=${nugeneFastqDir}/$(echo ${reads2FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
        echo "## "$(date)" ##  TMPFASTQ2= "$TMPFASTQ2

	
	if [ ${#reads2FqGz} -eq 0 ]; then
	        getFile ${reads1FqGz}
	        readspec=" -U ${reads1FqGz} "
	else
	    	getFile ${reads1FqGz}
	        getFile ${reads2FqGz}
	        readspec=" -1 ${reads1FqGz} -2 ${reads2FqGz} "
	fi


	if [ ${#reads2FqGz} -eq 0 ]; then
	        #single end no umi
		alloutputsexist \
		        ${nugeneReads1FqGz}

		getFile ${reads1FqGz}

		#ln -s ${reads1FqGz} ${nugeneReads1FqGz}

		#TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
                #echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1

                hisat2 -x ${onekgGenomeFastaIdxBase} $readspec --known-splicesite-infile ${hisat2SpliceKnownTxt} --score-min L,0,-0.6 --sp 1,1.5 -D 20 -R 3 -S ${nugeneReads1FqGz}.hisat2.sam --threads 1

		perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.hisat2.sam -b ${probeBed} -o $TMPFASTQ1 && rm -v ${nugeneReads1FqGz}.hisat2.sam

		bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=$TMPFASTQ1.fq.gz \
                 out=${nugeneReads1FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20 \
                 overwrite=t


		rm -v $TMPFASTQ1.fq.gz
                putFile ${nugeneReads1FqGz}
	else
		#paired end no umi
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}

		getFile ${reads1FqGz}
		getFile ${reads2FqGz}

#		bwa mem ${onekgGenomeFastaIdxBase} ${reads1FqGz}  ${reads2FqGz} > ${nugeneReads1FqGz}.bwamem.sam
#		
#		perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.bwamem.sam -b ${probeBed} -o $TMPFASTQ1 && rm -v ${nugeneReads1FqGz}.bwamem.sam

                hisat2 -x ${onekgGenomeFastaIdxBase} $readspec --known-splicesite-infile ${hisat2SpliceKnownTxt} --score-min L,0,-0.6 --sp 1,1.5 -D 20 -R 3 -S ${nugeneReads1FqGz}.hisat2.sam --threads 1

                perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.hisat2.sam -b ${probeBed} -o $TMPFASTQ1 && rm -v ${nugeneReads1FqGz}.hisat2.sam

		bash $EBROOTBBMAP/bbduk.sh \
	 	 -Xmx11g \
		 in=${TMPFASTQ1}_R1.fq.gz \
	 	 out=${nugeneReads1FqGz} \
                 in2=${TMPFASTQ1}_R2.fq.gz \
                 out2=${nugeneReads2FqGz} \
		 qtrim=r \
                 trimq=20 \
                 minlen=20 \
                 overwrite=t


		rm -v ${TMPFASTQ1}_R1.fq.gz ${TMPFASTQ1}_R2.fq.gz

		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}

	fi
else
	TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
        echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1
        TMPFASTQ2=${nugeneFastqDir}/$(echo ${reads2FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
        echo "## "$(date)" ##  TMPFASTQ2= "$TMPFASTQ2

	if [ ${#reads2FqGz} -eq 0 ]; then
	        getFile ${reads1FqGz}
	        readspec=" -U $TMPFASTQ1 "
	else
	    	getFile ${reads1FqGz}
	        getFile ${reads2FqGz}
	        readspec=" -1 $TMPFASTQ1 -2 $TMPFASTQ2 "
	fi

	if [ ${#reads2FqGz} -eq 0 ]; then
		#single end with umi
		alloutputsexist \
		        ${nugeneReads1FqGz}

		getFile ${reads1FqGz}

		perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles.pl ${reads3FqGz} ${nugeneFastqDir} ${reads1FqGz} 

		#TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		#echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1

                hisat2 -x ${onekgGenomeFastaIdxBase} $readspec --known-splicesite-infile ${hisat2SpliceKnownTxt} --score-min L,0,-0.6 --sp 1,1.5 -D 20 -R 3 -S ${nugeneReads1FqGz}.hisat2.sam --threads 1

               	perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.hisat2.sam -b ${probeBed} -o $TMPFASTQ1 && rm -v ${nugeneReads1FqGz}.hisat2.sam

                bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=$TMPFASTQ1.fq.gz \
                 out=${nugeneReads1FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20 \
		 overwrite=t


		rm -v $TMPFASTQ1 $TMPFASTQ1.fq.gz

		putFile ${nugeneReads1FqGz}

	else
		#paired end with umi
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}

		getFile ${reads1FqGz}
		getFile ${reads2FqGz}

	        perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles.pl ${reads3FqGz}  ${nugeneFastqDir} ${reads1FqGz} ${reads2FqGz}
		#TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		#echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1
		#TMPFASTQ2=${nugeneFastqDir}/$(echo ${reads2FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		#echo "## "$(date)" ##  TMPFASTQ2= "$TMPFASTQ2

		hisat2 -x ${onekgGenomeFastaIdxBase} $readspec --known-splicesite-infile ${hisat2SpliceKnownTxt} --score-min L,0,-0.6 --sp 1,1.5 -D 20 -R 3 -S ${nugeneReads1FqGz}.hisat2.sam --threads 1

               	perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.hisat2.sam -b ${probeBed} -o $TMPFASTQ1 && rm -v ${nugeneReads1FqGz}.hisat2.sam

               	bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=${TMPFASTQ1}_R1.fq.gz \
                 out=${nugeneReads1FqGz} \
                 in2=${TMPFASTQ1}_R2.fq.gz \
                 out2=${nugeneReads2FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20 \
		 overwrite=t


                rm -v ${TMPFASTQ1}_R1.fq.gz ${TMPFASTQ1}_R2.fq.gz

		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}
	fi
fi
