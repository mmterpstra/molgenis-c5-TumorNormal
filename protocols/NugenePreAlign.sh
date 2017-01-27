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

if [ ${#reads3FqGz} -eq 0 ]; then 
	if [ ${#reads2FqGz} -eq 0 ]; then
	        #single end no umi
		alloutputsexist \
		        ${nugeneReads1FqGz}

		getFile ${reads1FqGz}

		#ln -s ${reads1FqGz} ${nugeneReads1FqGz}

		bwa mem ${onekgGenomeFastaIdxBase} ${reads1FqGz} > ${nugeneReads1FqGz}.bwamem.sam

		perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.bwamem.sam -b ${probeBed} -o ${nugeneReads1FqGz}.trimbed.tmp && rm -v ${nugeneReads1FqGz}.bwamem.sam

		bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=${nugeneReads1FqGz}.trimbed.tmp.fq.gz \
                 out=${nugeneReads1FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20 \
		 overwrite=t

		rm -v ${nugeneReads1FqGz}.trimbed.tmp*.gz
                putFile ${nugeneReads1FqGz}
	else
		#paired end no umi
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}

		getFile ${reads1FqGz}
		getFile ${reads2FqGz}

		bwa mem ${onekgGenomeFastaIdxBase} ${reads1FqGz}  ${reads2FqGz} > ${nugeneReads1FqGz}.bwamem.sam
		
		perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.bwamem.sam -b ${probeBed} -o ${nugeneReads1FqGz}.trimbed.tmp && rm -v ${nugeneReads1FqGz}.bwamem.sam
		
		bash $EBROOTBBMAP/bbduk.sh \
	 	 -Xmx11g \
		 in=${nugeneReads1FqGz}.trimbed.tmp_R1.fq.gz \
	 	 out=${nugeneReads1FqGz} \
                 in2=${nugeneReads1FqGz}.trimbed.tmp_R2.fq.gz \
                 out2=${nugeneReads2FqGz} \
		 qtrim=r \
                 trimq=20 \
                 minlen=20 \
		 overwrite=t

		rm -v ${nugeneReads1FqGz}.trimbed.tmp*.gz

		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}

	fi
else
	if [ ${#reads2FqGz} -eq 0 ]; then
		#single end with umi
		alloutputsexist \
		        ${nugeneReads1FqGz}

		getFile ${reads1FqGz}

		perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles2.pl ${reads3FqGz} ${reads1FqGz} ${nugeneReads1FqGz}.mergefq.tmp.fq.gz

               	bwa mem ${onekgGenomeFastaIdxBase} ${nugeneReads1FqGz}.mergefq.tmp.fq.gz > ${nugeneReads1FqGz}.bwamem.sam

               	perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.bwamem.sam -b ${probeBed} -o ${nugeneReads1FqGz}.trimbed.tmp && rm -v ${nugeneReads1FqGz}.bwamem.sam

                bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=${nugeneReads1FqGz}.trimbed.tmp.fq.gz \
                 out=${nugeneReads1FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20 \
		 overwrite=t

		rm -v ${nugeneReads1FqGz}.mergefq.tmp.fq.gz ${nugeneReads1FqGz}.trimbed.tmp*.gz

		putFile ${nugeneReads1FqGz}

	else
		#paired end with umi
		alloutputsexist \
		        ${nugeneReads1FqGz}  ${nugeneReads2FqGz}

		getFile ${reads1FqGz}
		getFile ${reads2FqGz}

	        perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles2.pl ${reads3FqGz} ${reads1FqGz} ${nugeneReads1FqGz}.mergefq.tmp_1.fq.gz ${reads2FqGz} ${nugeneReads1FqGz}.mergefq.tmp_2.fq.gz

		bwa mem ${onekgGenomeFastaIdxBase} ${nugeneReads1FqGz}.mergefq.tmp_1.fq.gz ${nugeneReads1FqGz}.mergefq.tmp_2.fq.gz > ${nugeneReads1FqGz}.bwamem.sam

               	perl $EBROOTPIPELINEMINUTIL/bin/trimByBed.pl -s ${nugeneReads1FqGz}.bwamem.sam -b ${probeBed} -o ${nugeneReads1FqGz}.trimbed.tmp && rm -v ${nugeneReads1FqGz}.bwamem.sam

               	bash $EBROOTBBMAP/bbduk.sh \
                 -Xmx11g \
                 in=${nugeneReads1FqGz}.trimbed.tmp_R1.fq.gz \
                 out=${nugeneReads1FqGz} \
                 in2=${nugeneReads1FqGz}.trimbed.tmp_R2.fq.gz \
                 out2=${nugeneReads2FqGz} \
                 qtrim=r \
                 trimq=20 \
                 minlen=20 \
		 overwrite=t

                rm -v ${nugeneReads1FqGz}.trimbed.tmp*.gz ${nugeneReads1FqGz}.mergefq.tmp_[12].fq.gz

		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}
	fi
fi

echo "## "$(date)" ##  $0 Done "
