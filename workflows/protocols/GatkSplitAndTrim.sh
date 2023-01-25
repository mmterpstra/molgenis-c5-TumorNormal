#MOLGENIS nodes=1 ppn=1 mem=8gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string picardMod
#string samtoolsMod
#string onekgGenomeFasta
#string gatkOpt

#string markDuplicatesBam
#string markDuplicatesBai

#string splitAndTrimDir
#string splitAndTrimBam
#string splitAndTrimBai


echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${splitAndTrimBam} \
 ${splitAndTrimBai}

${stage} ${samtoolsMod}
${stage} ${gatkMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}

set -x
set -e

if [ ! -e ${splitAndTrimDir} ]; then
	mkdir -p ${splitAndTrimDir}
fi

#it botches on base quality scores use --allow_potentially_misencoded_quality_scores / the tool is not paralel with nt/nct
qualAction=$(samtools view ${markDuplicatesBam} | \
 head -1000000 | \
 awk '{gsub(/./,"&\n",$11);print $11}'| \
 sort -u| \
 perl -wne '
 $_=ord($_);
 print $_."\n"if(not($_=~/10/));' | \
 sort -n | \
 perl -wne '
 use strict;
 use List::Util qw/max sum min/;
 my @ords=<STDIN>;
 if(min(@ords) >= 33 && max(@ords) <= 80 && ((sum(@ords))/scalar(@ords))>76){
	#this is a quality score umi catch they tend to (almost?) exclusively use the higher quality scores and thus making quality detection by range impossible this is why i added the range 
	#barring any mayor leaps in sequencing this will last till 2030-2040 or beyond
	warn "Strange UMI like quals detected using:--allow_potentially_misencoded_quality_scores.";
	print " --allow_potentially_misencoded_quality_scores ";
 }elsif(min(@ords) >= 59 && max(@ords) <=104 ){
	print " --fix_misencoded_quality_scores ";
	warn "Illumina <= 1.7 scores detected using:--fix_misencoded_quality_scores.\n";
 }elsif(min(@ords) >= 33 && max(@ords) <= 74){
	print " ";
	warn "quals > illumina 1.8 detected no action to take.\n";
 }elsif(min(@ords) >= 33 && max(@ords) <= 80){
	print " --allow_potentially_misencoded_quality_scores "; 
	warn "Strange illumina like quals detected using:--allow_potentially_misencoded_quality_scores.";
 }else{
	die "Cannot estimate quality scores here is the list:".join(",",@ords)."\n";
 }
')

#this cleans up DN combinations (which is an invalid CIGAR tag combination)
samtools view -h ${markDuplicatesBam} | \
    perl -wape 'while($F[5] =~ m/(\d+)[DN](\d+)[DN]/){
            substr($_,index($_,$&),length($&),($1+$2)."N");
            substr($F[5],index($F[5],$&),length($&),($1+$2)."N");
        }
        my $samfieldindex = 11;
        while($samfieldindex < scalar(@F)){
            #warn $outer
            if($F[$samfieldindex] =~ m/Y[AO]:Z:/){
                while($F[$samfieldindex] =~ m/(\d+)[DN](\d+)[DN]/){
                    #warn $samfieldindex."\t".$_;
                    substr($_,index($_,$&),length($&),($1+$2)."N");
                    substr($F[$samfieldindex],index($F[$samfieldindex],$&),length($&),($1+$2)."N");
                }
            }
            $samfieldindex++;
        }' | samtools view -Sb > ${splitAndTrimBam}.cigarfixed.bam
samtools index ${splitAndTrimBam}.cigarfixed.bam
#more fixups
(ml picard;
	java  -Xmx5g -XX:ParallelGCThreads=2 \
	-Djava.io.tmpdir="${splitAndTrimDir}" \
	-jar $EBROOTPICARD/picard.jar FixMateInformation \
	INPUT="${splitAndTrimBam}.cigarfixed.bam" \
	ADD_MATE_CIGAR=true IGNORE_MISSING_MATES=true  ASSUME_SORTED=false \
	SORT_ORDER=coordinate  CREATE_INDEX=true  TMP_DIR="${splitAndTrimDir}" \
	OUTPUT="${splitAndTrimBam}.cigarmatefixed.bam" )
(ml picard;
	java -Xmx5g -XX:ParallelGCThreads=2 \
	-Djava.io.tmpdir="${splitAndTrimDir}" \
	-jar $EBROOTPICARD/picard.jar SetNmMdAndUqTags \
	--INPUT "${splitAndTrimBam}.cigarmatefixed.bam" \
	--OUTPUT "${splitAndTrimBam}.cigarmatetagfixed.bam" \
	-R ${onekgGenomeFasta}; )


java -Xmx8g -Djava.io.tmpdir=${splitAndTrimDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T SplitNCigarReads \
 -R ${onekgGenomeFasta} \
 -I ${splitAndTrimBam}.cigarfixed.bam \
 -o ${splitAndTrimBam} \
 -rf ReassignOneMappingQuality \
 -RMQF 255 \
 -RMQT 60 \
 $qualAction \
 ${gatkOpt}

cp -v ${splitAndTrimBai} ${splitAndTrimBam}.bai

putFile ${splitAndTrimBam}
putFile ${splitAndTrimBai}
putFile ${splitAndTrimBam}.bai


echo "## "$(date)" ##  $0 Done "
