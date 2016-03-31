#MOLGENIS nodes=1 ppn=1 mem=8gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
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
 use List::Util qw/max min/;
 my @ords=<STDIN>;
 if(min(@ords) >= 59 && max(@ords) <=104 ){
	print " --fix_misencoded_quality_scores ";
	warn "Illumina <= 1.7 scores detected using:--fix_misencoded_quality_scores.\n";
 }elsif(min(@ords) >= 33 && max(@ords) <= 74){
	print " ";
	warn "quals > illumina 1.8 detected no action to take.\n";
 }elsif(min(@ords) >= 33 && max(@ords) <= 80){
	print " --allow_potentially_misencoded_quality_scores "; 
	warn "Strange illumina like quals detected using:--allow_potentially_misencoded_quality_scores."
 }else{
	die "Cannot estimate quality scores here is the list:".join(",",@ords)."\n";
 }
')





java -Xmx8g -Djava.io.tmpdir=${splitAndTrimDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T SplitNCigarReads \
 -R ${onekgGenomeFasta} \
 -I ${markDuplicatesBam} \
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
