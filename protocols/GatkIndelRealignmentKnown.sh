#MOLGENIS nodes=1 ppn=1 mem=8gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string samtoolsMod
#string onekgGenomeFasta
#string indelRealignmentTargets
#string goldStandardVcf
#string goldStandardVcfIdx
#string oneKgPhase1IndelsVcf
#string oneKgPhase1IndelsVcfIdx
#string gatkOpt

#string markDuplicatesBam
#string markDuplicatesBai

#string indelRealignmentDir
#string indelRealignmentBam
#string indelRealignmentBai

#pseudo from gatk forum (link: http://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_sting_gatk_walkers_indels_IndelRealigner):
#java -Xmx4g -jar GenomeAnalysisTK.jar -T IndelRealigner -R ref.fa -I input.bam -targetIntervals intervalListFromRTC.intervals -o realignedBam.bam [-known /path/to/indels.vcf] -U ALLOW_N_CIGAR_READS --allow_potentially_misencoded_quality_scores

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${indelRealignmentBam} \
 ${indelRealignmentBai}

${stage} ${samtoolsMod}
${stage} ${gatkMod}
${checkStage}

getFile ${onekgGenomeFasta}
getFile ${markDuplicatesBam}
getFile ${markDuplicatesBai}
getFile ${indelRealignmentTargets}
getFile ${oneKgPhase1IndelsVcf}
getFile ${goldStandardVcf}
getFile ${oneKgPhase1IndelsVcfIdx}
getFile ${goldStandardVcfIdx}

set -x
set -e

if [ ! -e ${indelRealignmentDir} ]; then
	mkdir -p ${indelRealignmentDir}
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


java -Xmx8g -Djava.io.tmpdir=${indelRealignmentDir}  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -T IndelRealigner \
 -R ${onekgGenomeFasta} \
 -I ${markDuplicatesBam} \
 -o ${indelRealignmentBam} \
 -targetIntervals ${indelRealignmentTargets} \
 -known ${oneKgPhase1IndelsVcf} \
 -known ${goldStandardVcf} \
 --consensusDeterminationModel KNOWNS_ONLY \
 --LODThresholdForCleaning 0.4 \
 $qualAction \
 ${gatkOpt}

cp -v ${indelRealignmentBai} ${indelRealignmentBam}.bai

putFile ${indelRealignmentBam}
putFile ${indelRealignmentBai}
putFile ${indelRealignmentBam}.bai


echo "## "$(date)" ##  $0 Done "
