#MOLGENIS nodes=1 ppn=1 mem=12gb walltime=10:00:00

#string project

#Parameter mapping

#string stage
#string checkStage
#string bbmapMod
#string digiRgMod
#string pipelineUtilMod
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

#check modules
${checkStage}


set -x
set -e

mkdir -p ${nugeneFastqDir}

#if possible add umi
	#if possible do paired end
		#trim with bbduk

if [ ${#reads3FqGz} -eq 0 ]; then 
	if [ ${#reads2FqGz} -eq 0 ]; then
	        #single end no umi
		alloutputsexist \
		        ${nugeneReads1FqGz}

		getFile ${reads1FqGz}

		bash $EBROOTBBMAP/bbduk.sh \
		 in=${reads1FqGz} \
		 out=${nugeneReads1FqGz} \
		 ref=${probeFa} \
		 hdist=1 \
		 ktrim=r \
		 rcomp=f \
		 k=31 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20		
		
                putFile ${nugeneReads1FqGz}
	else
		#paired end no umi
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}

		getFile ${reads1FqGz}
		getFile ${reads2FqGz}

		TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1
		TMPFASTQ2=${nugeneFastqDir}/$(echo ${reads2FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ2= "$TMPFASTQ2
		
		bash $EBROOTBBMAP/bbduk.sh \
		 in=${reads1FqGz} \
		 out=${nugeneReads1FqGz} \
		 in2=${reads2FqGz} \
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

		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}

	fi
else
	if [ ${#reads2FqGz} -eq 0 ]; then
		#single end with umi
		alloutputsexist \
		        ${nugeneReads1FqGz}

		getFile ${reads1FqGz}

		perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles.pl -u ${reads3FqGz} ${nugeneFastqDir} ${reads1FqGz} 

		TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1

		bash $EBROOTBBMAP/bbduk.sh \
		 in=$TMPFASTQ1 \
		 out=${nugeneReads1FqGz} \
		 ref=${probeFa} \
		 hdist=1 \
		 ktrim=r \
		 rcomp=f \
		 k=31 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20

		rm -v $TMPFASTQ1

		putFile ${nugeneReads1FqGz}

	else
		#paired end with umi
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}

		getFile ${reads1FqGz}
		getFile ${reads2FqGz}

	        perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles.pl -u ${reads3FqGz}  ${nugeneFastqDir} ${reads1FqGz} ${reads2FqGz}
		TMPFASTQ1=${nugeneFastqDir}/$(echo ${reads1FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ1= "$TMPFASTQ1
		TMPFASTQ2=${nugeneFastqDir}/$(echo ${reads2FqGz}| perl -wpe 's/^.*\/|\.fastq\.gz|\.fq\.gz//g;chomp').fq.gz
		echo "## "$(date)" ##  TMPFASTQ2= "$TMPFASTQ2

               	bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=${TMPFASTQ1} \
                 out=${nugeneReads1FqGz} \
                 in2=${TMPFASTQ2} \
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

                rm -v ${TMPFASTQ1}_R1.fq.gz ${TMPFASTQ1}_R2.fq.gz

		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}
	fi
fi

echo "## "$(date)" ##  $0 Done "
