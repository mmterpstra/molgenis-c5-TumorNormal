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

if [ ${#reads3FqGz} -eq 0 ]; then 
	if [ ${#reads2FqGz} -eq 0 ]; then
	        alloutputsexist \
		        ${nugeneReads1FqGz}
		
		getFile ${reads1FqGz}
		
		#ln -s ${reads1FqGz} ${nugeneReads1FqGz}
		
		TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
                echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1
		
		readspec=" -U ${reads1FqGz} "
		hisat2 -x ${onekgGenomeFastaIdxBase} $readspec -S ${nugeneReads1FqGz}.hisat2.sam --threads 1
		perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.hisat2.sam -b ${probeBed} -i ${reads1FqGz} -o $TMPFASTQ1
		 
		bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=$TMPFASTQ1 \
                 out=${nugeneReads1FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20
		
		rm -v $TMPFASTQ1 ${nugeneReads1FqGz}.hisat2.sam
		
                putFile ${nugeneReads1FqGz}
	else
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}
		
	    	getFile ${reads1FqGz}
		getFile ${reads2FqGz}
		
	        perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles.pl ${reads3FqGz}  ${nugeneFastqDir} ${reads1FqGz} ${reads2FqGz}
		TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1		
		TMPFASTQ2=${nugeneFastqDir}/$(echo ${reads2FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ2= "$TMPFASTQ2
		
		bash $EBROOTBBMAP/bbduk.sh \
	 	 -Xmx11g \
		 in=$TMPFASTQ1 \
	 	 out=${nugeneReads1FqGz} \
                 in2=$TMPFASTQ2 \
                 out2=${nugeneReads2FqGz} \
	 	 ref=${probeFa} \
	 	 hdist=1 \
	 	 ktrim=r \
	 	 rcomp=f \
	 	 k=31 \
	 	 mink=11 \
	 	 qtrim=r \
	 	 trimq=20 \
	 	 minlen=20 
		
		rm -v $TMPFASTQ1 $TMPFASTQ2
		
		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}

	fi
else
	if [ ${#reads2FqGz} -eq 0 ]; then
	        alloutputsexist \
		        ${nugeneReads1FqGz}

		getFile ${reads1FqGz}
		
		perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles.pl ${reads3FqGz} ${nugeneFastqDir} ${reads1FqGz} 

		TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1
		
               	readspec=" -U ${reads1FqGz} "
                hisat2 -x ${onekgGenomeFastaIdxBase} $readspec -S ${nugeneReads1FqGz}.hisat2.sam --threads 1
                perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.hisat2.sam -b ${probeBed} -i $TMPFASTQ1 -o $TMPFASTQ1.bedtrimmed.fq.gz
		
                bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=$TMPFASTQ1.bedtrimmed.fq.gz \
                 out=${nugeneReads1FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20

		rm -v $TMPFASTQ1 $TMPFASTQ1.bedtrimmed.fq.gz ${nugeneReads1FqGz}.hisat2.sam

		putFile ${nugeneReads1FqGz}

	else
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}
		
		getFile ${reads1FqGz}
		getFile ${reads2FqGz}
		
	        perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles.pl ${reads3FqGz}  ${nugeneFastqDir} ${reads1FqGz} ${reads2FqGz}
		TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1		
		TMPFASTQ2=${nugeneFastqDir}/$(echo ${reads2FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ2= "$TMPFASTQ2
		
		bash $EBROOTBBMAP/bbduk.sh \
	 	 -Xmx11g \
		 in=$TMPFASTQ1 \
	 	 out=${nugeneReads1FqGz} \
                 in2=$TMPFASTQ2 \
                 out2=${nugeneReads2FqGz} \
	 	 ref=${probeFa} \
	 	 hdist=1 \
	 	 ktrim=r \
	 	 rcomp=f \
	 	 k=31 \
	 	 mink=11 \
	 	 qtrim=r \
	 	 trimq=20 \
	 	 minlen=20 
		
		rm -v $TMPFASTQ1 $TMPFASTQ2
		
		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}
	fi
fi

echo "## "$(date)" ##  $0 Done "
