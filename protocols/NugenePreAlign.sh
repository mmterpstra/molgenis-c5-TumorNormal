#MOLGENIS nodes=1 ppn=1 mem=12gb walltime=10:00:00

#string project

#Parameter mapping

#string stage
#string checkStage
#string bbmapMod
#string digiRgMod
#string pipelineUtilMod
#string probeFa
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


getFile ${reads1FqGz}

if [ ${#reads3FqGz} -eq 0 ]; then
	#no umi
        if [ ${#reads2FqGz} -eq 0 ]; then
		#single end
		alloutputsexist \
		 ${nugeneReads1FqGz}

		bash $EBROOTBBMAP/bbduk.sh \
		 in=${reads1FqGz} \
		 out=${nugeneReads1FqGz} \
		 literal='GAGAGCGATCCTTGC,GGGGGGGGGGGGGGG' \
		 hdist=1 \
		 ktrim=r \
		 rcomp=f \
		 k=15 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20

	else
		#paired end
		getFile ${reads2FqGz}
		alloutputsexist \
		 ${nugeneReads1FqGz}  ${nugeneReads2FqGz}
		
		bash $EBROOTBBMAP/bbduk.sh \
		 in=${reads1FqGz} \
		 out=${nugeneReads1FqGz}.tmpbbduk.1.fq.gz \
		 in2=${reads2FqGz} \
		 out2=${nugeneReads2FqGz}.tmpbbduk.2.fq.gz \
		 literal='GAGAGCGATCCTTGC,GGGGGGGGGGGGGGG' \
		 hdist=1 \
		 ktrim=r \
		 rcomp=f \
		 k=15 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20 \
		 skipr2=t

		bash $EBROOTBBMAP/bbduk.sh \
		 in=${nugeneReads1FqGz}.tmpbbduk.1.fq.gz \
		 out=${nugeneReads1FqGz} \
		 in2=${nugeneReads2FqGz}.tmpbbduk.2.fq.gz \
		 out2=${nugeneReads2FqGz} \
		 literal=$( perl -we '$_ = shift @ARGV or die "No Args";chomp; $_=reverse($_)."\n";tr/atcgnATCGN/tagcnTAGCN/; print' 'GAGAGCGATCCTTGC') \
		 hdist=1 \
		 ktrim=l \
		 rcomp=f \
		 k=15 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20 \
		 skipr1=t
		
		#rm -v ${nugeneReads1FqGz}.tmpbbduk.1.fq.gz ${nugeneReads2FqGz}.tmpbbduk.2.fq.gz
		
	fi
else
	#umi
	getFile ${reads3FqGz}

	if [ ${#reads2FqGz} -eq 0 ]; then
		
		#single end + umi => get random barcode in read + trim nugene linker
		alloutputsexist \
		 ${nugeneReads1FqGz}
		
		perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles2.pl \
		 ${reads3FqGz} \
		 ${reads1FqGz} ${nugeneReads1FqGz}.tmpmergefq.1.fq.gz

		bash $EBROOTBBMAP/bbduk.sh \
		 in=${nugeneReads1FqGz}.tmpmergefq.1.fq.gz \
		 out=${nugeneReads1FqGz} \
		 literal='GAGAGCGATCCTTGC,GGGGGGGGGGGGGGG' \
		 hdist=1 \
		 ktrim=r \
		 rcomp=f \
		 k=15 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20

		putFile ${nugeneReads1FqGz}
       	else
		#paired end
		getFile ${reads2FqGz}
		alloutputsexist \
		 ${nugeneReads1FqGz}  ${nugeneReads2FqGz}
		
	        perl $EBROOTDIGITALBARCODEREADGROUPS/src/NugeneMergeFastqFiles2.pl \
		 ${reads3FqGz} \
		 ${reads1FqGz} ${nugeneReads1FqGz}.tmpmergefq.1.fq.gz \
		 ${reads2FqGz} ${nugeneReads2FqGz}.tmpmergefq.2.fq.gz

		bash $EBROOTBBMAP/bbduk.sh \
		 in=${nugeneReads1FqGz}.tmpmergefq.1.fq.gz \
		 out=${nugeneReads1FqGz}.tmpbbduk.1.fq.gz \
		 in2=${nugeneReads2FqGz}.tmpmergefq.2.fq.gz \
		 out2=${nugeneReads2FqGz}.tmpbbduk.2.fq.gz \
		 literal='GAGAGCGATCCTTGC,GGGGGGGGGGGGGGG' \
		 hdist=1 \
		 ktrim=r \
		 rcomp=f \
		 k=15 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20 \
		 skipr2=t

		bash $EBROOTBBMAP/bbduk.sh \
		 in=${nugeneReads1FqGz}.tmpbbduk.1.fq.gz \
		 out=${nugeneReads1FqGz} \
		 in2=${nugeneReads2FqGz}.tmpbbduk.2.fq.gz \
		 out2=${nugeneReads2FqGz} \
		 literal=$( perl -we '$_ = shift @ARGV or die "No Args";chomp; $_=reverse($_)."\n";tr/atcgnATCGN/tagcnTAGCN/; print' 'GAGAGCGATCCTTGC') \
		 hdist=1 \
		 ktrim=l \
		 rcomp=f \
		 k=15 \
		 mink=11 \
		 qtrim=r \
		 trimq=20 \
		 minlen=20 \
		 skipr1=t 

		putFile ${nugeneReads1FqGz}
		putFile ${nugeneReads2FqGz}
       	fi
fi

echo "## "$(date)" ##  $0 Done "
