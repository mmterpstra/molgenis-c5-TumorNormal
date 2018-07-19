#MOLGENIS nodes=1 ppn=7 mem=40gb walltime=10:00:00

#string project



#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string starMod
#string picardMod
#string samtoolsMod
#string onekgGenomeFasta
#string onekgGenomeFastaIdxBase
#string hisat2SpliceKnownTxt
#string hisat2AlignmentDir
#string starSam
#string starSampleDir
#string nTreads
#string reads1FqGz
#string reads2FqGz
#string reads1FqGzOriginal
#string reads2FqGzOriginal
#string starIndexDir

echo "## "$(date)" ##  $0 Started "

#Check if output exists if so execute 'exit -0'
alloutputsexist \
	${starSam}


(
#getFile functions

	getFile ${onekgGenomeFasta} ${hisat2SpliceKnownTxt}

	#Load modules
	${stage} ${starMod}
	${stage} ${picardMod}
	${stage} ${samtoolsMod}

	#check modules
	${checkStage}


	set -x
	set -e

	mkdir -p ${starSampleDir}
	cd ${starSampleDir}

	#hisat2 -x /apps/data/ftp.broadinstitute.org/bundle/2.8/b37/hisat2/2.0.3-beta-goolf-1.7.20/human_g1k_v37_decoy {-1 <m1> -2 <m2> | -U <r>} [-S <sam>]

	if [ ${#reads2FqGzOriginal} -eq 0 ]; then
		getFile ${reads1FqGz}
		readspec=" --readFilesIn ${reads1FqGz} "
	else
		getFile ${reads1FqGz}
		getFile ${reads2FqGz}
		readspec=" --readFilesIn ${reads1FqGz} ${reads2FqGz} "
	fi
	if [ ${#reads2FqGz} -eq 0 ]; then
		getFile ${reads1FqGz}
		echo "## "$(date)" ## Single-end readlength test"
		readLength=$(gzip -dc ${reads1FqGz} | \
			head -10000 | \
			perl -we 'use strict;use List::Util qw/max/; my $in;$in=*STDIN; my @l;while(<$in>){chomp;my $line = $_;  push(@l, length($line)) if(($. % 4 )==2);}; my $sjboh=(max(@l)); print $sjboh."\n"')
		let 'sjdbOverhang=readLength - 1'
	else	
		getFile ${reads1FqGz}
		getFile ${reads2FqGz}
		echo "## "$(date)" ## Paired-end readlength test"
		
		readLength1=$(gzip -dc ${reads1FqGz} | \
			head -10000 | \
			perl -we 'use strict;use List::Util qw/max/; my $in;$in=*STDIN; my @l;while(<$in>){chomp;my $line = $_;  push(@l, length($line)) if(($. % 4 )==2);}; my $sjboh=(max(@l)); print $sjboh."\n"')
		
		readLength2=$(gzip -dc ${reads2FqGz} | \
			head -10000 | \
			perl -we 'use strict;use List::Util qw/max/; my $in;$in=*STDIN; my @l;while(<$in>){chomp;my $line = $_;  push(@l, length($line)) if(($. % 4 )==2);}; my $sjboh=(max(@l)); print $sjboh."\n"')
		#for sjdbOverhang the best thing to use is max read length -1: shorter than max read length migth result in sloppy alignments near intron-exon borders but possibly better mapq. max read length migth result into good alignments near intron-exon borders but possibly worse mapq for shorter reads.
		if [  $readLength1 -le  $readLength2 ]; then 
			let 'sjdbOverhang=readLength2 - 1'
		elif [  $readLength1 -gt  $readLength2 ]; then 
			let 'sjdbOverhang=readLength1 - 1'
		fi
	fi
	
	echo "## "$(date)" ##  $0 Align with star with readspec='$readspec' sjdbOverhang='$sjdbOverhang'"
	
	STAR \
	 --genomeDir ${starIndexDir}/sjdboverhang_${sjdbOverhang} \
	 $readspec \
	 --runThreadN 6 \
	 --readFilesCommand "zcat " \
	 --chimSegmentMin 15 \
	 --chimJunctionOverhangMin 15 
)
echo "## "$(date)" ##  $0 Done "
