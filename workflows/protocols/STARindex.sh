#MOLGENIS nodes=1 ppn=7 mem=40gb walltime=10:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string starMod
#string samtoolsMod
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string ensemblAnnotationGtf
#string starIndexDir
#string nTreads
#list reads1FqGz,reads2FqGz,reads1FqGzOriginal,reads2FqGzOriginal


echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'


alloutputsexist \
	 ${starIndexDir}/sjdboverhang


#getFile functions

getFile ${onekgGenomeFasta}

#Load modules
${stage} ${starMod}
${stage} ${samtoolsMod}

#check modules
${checkStage}


set -x
set -e

mkdir -p ${starIndexDir}

for fq in ${reads1FqGz[@]} ${reads2FqGz[@]} ${reads1FqGzOriginal[@]} ${reads2FqGzOriginal[@]}; do 
	if [ -e $fq ] ; then
		
		readLength=$(gzip -dc ${fq} | \
			head -10000 | \
			perl -we 'use strict;use List::Util qw/max/; my $in;$in=*STDIN; my @l;while(<$in>){chomp;my $line = $_;  push(@l, length($line)) if(($. % 4 )==2);}; my $sjboh=(max(@l)); print $sjboh."\n"')
		let 'sjdbOverhang=readLength - 1'
		
		echo "## "$(date)" ##sjdbOverhang determined. sjdbOverhang=$sjdbOverhang"
		
		if [ ! -e ${starIndexDir}/sjdboverhang_$sjdbOverhang ] ; then
	                echo "## "$(date)" ## Genome index not present generating it now"
			mkdir -p ${starIndexDir}/sjdboverhang_$sjdbOverhang
			STAR \
			 --runMode genomeGenerate \
			 --genomeDir ${starIndexDir}/sjdboverhang_$sjdbOverhang \
			 --genomeFastaFiles ${onekgGenomeFasta} \
			 --sjdbGTFfile ${ensemblAnnotationGtf}\
			 --sjdbOverhang $sjdbOverhang \
			 --runThreadN 6
		fi
		putFile ${starIndexDir}/sjdboverhang_$sjdbOverhang

	fi

done


putFile ${starIndexDir}

echo "## "$(date)" ##  $0 Done "
