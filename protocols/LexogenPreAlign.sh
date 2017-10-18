#MOLGENIS nodes=1 ppn=1 mem=5gb walltime=10:00:00

#string project

#Parameter mapping

#string stage
#string checkStage
#string bbmapMod
#string digiRgMod
#string pipelineUtilMod
#string probeFa
#string probeBed
#string lexogenFastqDir

#string reads1FqGz
#string reads2FqGz
#string reads3FqGz

#string lexogenReads1FqGz
#string lexogenReads2FqGz


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

mkdir -p ${lexogenFastqDir}


getFile ${reads1FqGz}

if [ ${#reads2FqGz} -eq 0 ]; then
	#single end
	alloutputsexist \
	 ${lexogenReads1FqGz}
	bash $EBROOTBBMAP/bbduk.sh -Xmx3g \
	 t=2 \
	 in=${reads1FqGz} \
	 out=${lexogenReads1FqGz} \
	 literal='GAGAGCGATCCTTGC,GGGGGGGGGGGGGGG,AAAAAAAAAAAAAAA' \
	 hdist=1 \
	 ktrim=r \
	 rcomp=f \
	 k=15 \
	 mink=11 \
	 qtrim=r \
	 trimq=20 \
	 minlen=20 
	 #forcetrimleft=11
else
	#paired end
	getFile ${reads2FqGz}
	alloutputsexist \
	 ${lexogenReads1FqGz}  ${lexogenReads2FqGz}
	
	bash $EBROOTBBMAP/bbduk.sh -Xmx3g \
	 t=2 \
	 in=${reads1FqGz} \
	 out=${lexogenReads1FqGz}.tmpbbduk.1.fq.gz \
	 in2=${reads2FqGz} \
	 out2=${lexogenReads2FqGz}.tmpbbduk.2.fq.gz \
	 literal='GAGAGCGATCCTTGC,GGGGGGGGGGGGGGG,AAAAAAAAAAAAAAA' \
	 hdist=1 \
	 ktrim=r \
	 rcomp=f \
	 k=15 \
	 mink=11 \
	 qtrim=r \
	 trimq=20 \
	 minlen=20 \
	 skipr2=t

	bash $EBROOTBBMAP/bbduk.sh -Xmx3g \
	 t=2 \
	 in=${lexogenReads1FqGz}.tmpbbduk.1.fq.gz \
	 out=${lexogenReads1FqGz} \
	 in2=${lexogenReads2FqGz}.tmpbbduk.2.fq.gz \
	 out2=${lexogenReads2FqGz} \
	 literal=$( perl -we '$_ = shift @ARGV or die "No Args";chomp; $_=reverse($_)."\n";tr/atcgnATCGN/tagcnTAGCN/; print' 'GAGAGCGATCCTTGC'),GGGGGGGGGGGGGGG,AAAAAAAAAAAAAAA' \
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

echo "## "$(date)" ##  $0 Done "
