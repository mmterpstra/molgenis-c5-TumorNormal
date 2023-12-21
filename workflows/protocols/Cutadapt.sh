#MOLGENIS nodes=1 ppn=2 mem=4gb walltime=10:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string cutadaptMod
#string cutadaptDir
#string cutadapt1FqGz
#string cutadapt2FqGz
#string nTreads
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${cutadapt1FqGz}
 
#getFile functions

#Load modules
${stage} ${cutadaptMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p "${cutadaptDir}"
#mkdir -p ${trimgaloreSampleDir}

#(ml Trim_Galore/0.6.6-GCCcore-9.3.0-Python-3.8.2 ;mkdir -p $outdir;  trim_galore --paired $fq1 $fq2 --output_dir $outdir )


if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	getFile "${reads1FqGz}"
	
	cutadapt  \
		-j 1 -e 0.1 -q 20 -O 1 \
		-a NNNNNNNAGATCGGAAGAGC \
		--minimum-length 15 \
		--output "${cutadapt1FqGz}" \
		"${reads1FqGz}" \
		&>  ${cutadapt1FqGz}"_trimming_report.txt"
else
	getFile "${reads1FqGz}"
	getFile "${reads2FqGz}"
	cutadapt  -j 1 \
		-e 0.1 -q 20 -O 1 \
		-a NNNNNNNAGATCGGAAGAGC \
		-A NNNNNNNAGATCGGAAGAGC \
		--minimum-length 15:15 \
		--output "${cutadapt1FqGz}" \
		--paired-output "${cutadapt2FqGz}" \
		"${reads1FqGz}" \
		"${reads2FqGz}" \
		&>  "${cutadapt1FqGz}""_trimming_report.txt"
        putFile "${cutadapt2FqGz}"
fi

putFile "${cutadapt1FqGz}"
putFile "${cutadapt1FqGz}""_trimming_report.txt"

echo "## "$(date)" ##  $0 Done "
