#MOLGENIS nodes=1 ppn=1 mem=1gb walltime=10:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string trimgaloreMod
#string trimgaloreDir
#string trimgaloreSampleDir
#string trimgalore1FqGz
#string trimgalore2FqGz
#string nTreads
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	trimgalore1FqGz
 
#getFile functions

#Load modules
${stage} ${trimgaloreMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${trimgaloreDir}
mkdir -p ${trimgaloreSampleDir}

#(ml Trim_Galore/0.6.6-GCCcore-9.3.0-Python-3.8.2 ;mkdir -p $outdir;  trim_galore --paired $fq1 $fq2 --output_dir $outdir )


if [ ${#reads2FqGzOriginal} -eq 0 ]; then
	getFile ${reads1FqGz}
	
	trim_galore "${reads1FqGz}" \
	 --output_dir "${trimgaloreSampleDir}"
	mv "${trimgaloreSampleDir}/$(basename "$(basename "${reads1FqGz}"  .fq.gz)" .fastq.gz)_trimmed.fq.gz"  "${trimgalore1FqGz}"
else
	getFile ${reads1FqGz}
	getFile ${reads2FqGz}
        trim_galore --paired "${reads1FqGz}" "${reads2FqGz}" \
         --output_dir "${trimgaloreSampleDir}"
        if [ -e   "${trimgaloreSampleDir}/$(basename "$(basename "${reads1FqGz}" .fq.gz)" .fastq.gz)_val_"1".fq.gz" ]; then
            mv "${trimgaloreSampleDir}/$(basename "$(basename "${reads1FqGz}" .fq.gz)" .fastq.gz)_val_"1".fq.gz"  "${trimgalore1FqGz}"       
	    mv "${trimgaloreSampleDir}/$(basename "$(basename "${reads2FqGz}" .fq.gz)" .fastq.gz)_val_"2".fq.gz"  "${trimgalore2FqGz}"
        elif [ -e "${trimgaloreSampleDir}/$(basename "$(basename "${reads1FqGz}" .fq.gz)" .fastq.gz)_val_"2".fq.gz" ]; then
            mv "${trimgaloreSampleDir}/$(basename "$(basename "${reads1FqGz}" .fq.gz)" .fastq.gz)_val_"2".fq.gz"  "${trimgalore1FqGz}"
            mv "${trimgaloreSampleDir}/$(basename "$(basename "${reads2FqGz}" .fq.gz)" .fastq.gz)_val_"1".fq.gz"  "${trimgalore2FqGz}"
	fi
        putFile ${trimgalore2FqGz}
fi

putFile ${trimgalore1FqGz}

echo "## "$(date)" ##  $0 Done "
