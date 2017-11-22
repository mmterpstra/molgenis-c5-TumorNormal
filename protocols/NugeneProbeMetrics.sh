#MOLGENIS nodes=1 ppn=6 mem=6gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string bedtoolsMod
#string samtoolsMod

#string probeBed
#string onekgGenomeFasta

#string indelRealignmentBam
#string indelRealignmentBai
#string nugeneProbeMetricsDir
#string nugeneProbeMetricsLog
#string nugeneProbeMetricsDeDupLog
echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${nugeneProbeMetricsLog} ${nugeneProbeMetricsDeDupLog}

getFile ${onekgGenomeFasta}
getFile ${probeBed}
getFile ${indelRealignmentBam}
getFile ${indelRealignmentBai}

${stage} ${bedtoolsMod}
${stage} ${samtoolsMod}
${checkStage}

set -x -e -o pipefail

mkdir -p ${nugeneProbeMetricsDir}

NUGLOG="${nugeneProbeMetricsLog}.counts300bp.dedup.log"
echo -e "chr\tstart\tend\tname\tscore\tstrand\tcount\tNotZeroCoverage\tLength\tpctNotZeroCoverage" > "${NUGLOG}"

bedtools coverage \
 -S \
 -a <( bedtools sort \
	 -i <(bedtools flank \
		 -i <(bedtools sort -i ${probeBed}) \
		 -l 0 -r 300 -s \
		 -g <(cut -f1,2 ${onekgGenomeFasta}.fai))) \
  -b <(samtools view -Sb -F 1024 -q 20 ${indelRealignmentBam}) \
 >> "${NUGLOG}"

NUGLOG="${nugeneProbeMetricsLog}.counts300bp.log"
echo -e "chr\tstart\tend\tname\tscore\tstrand\tcount\tNotZeroCoverage\tLength\tpctNotZeroCoverage" > "${NUGLOG}"

bedtools coverage \
 -S \
 -a <( bedtools sort \
         -i <(bedtools flank \
                 -i <(bedtools sort -i ${probeBed}) \
                 -l 0 -r 300 -s \
                 -g <(cut -f1,2 ${onekgGenomeFasta}.fai))) \
 -b <(samtools view -Sb -q 20 ${indelRealignmentBam}) \
 >> "${NUGLOG}"


# bedtools coverage -S -abam <(samtools view -Sb -F 1024 -q 20 /scratch/umcg-mterpstra/projects/NugeneInc2_Ferronika_10aug2017/indelRealignment/NUG_R5A3_500ng.bam) -b  <(bedtools sort -i <(bedtools flank -i <(bedtools sort -i /data/umcg-mterpstra/apps/data/resources/probeSeq_RDonly_ET1262F_2_182.bed) -l 0 -r 300 -s -g <(cut -f1,2 /data/umcg-mterpstra/apps/data/ftp.broadinstitute.org/bundle/2.8/b37/human_g1k_v37_decoy.fasta.fai)))

bedtools closest -D 'a' -fd -iu -S -a \
	<(bedtools sort -i \
		<(bedtools bamtobed  -i ${indelRealignmentBam}))\
 -b  \
	<(bedtools sort -i \
		<(bedtools slop \
		 -l 60 \
		 -r -60 \
		 -s \
		 -i ${probeBed} \
		 -g <(cut -f1,2 ${onekgGenomeFasta}.fai))) | \
awk '{if($13 < 600 &&  $10 != "." ){print $0}}' | \
cut -f7,8,9,10,11,12| sort | \
cat - \
	<(bedtools sort -i \
                <(bedtools slop \
                 -l 60 \
                 -r -60 \
                 -s \
                 -i ${probeBed} \
                 -g <(cut -f1,2 ${onekgGenomeFasta}.fai))) | \
sort | \
uniq -c  > ${nugeneProbeMetricsLog}

bedtools closest -D 'a' -fd -iu -S -a \
        <(bedtools sort -i \
                <(bedtools bamtobed  -i \
			<(samtools view -hb -F 1024 ${indelRealignmentBam})))\
 -b  \
      	<(bedtools sort -i \
                <(bedtools slop \
                 -l 60 \
                 -r -60 \
                 -s \
                 -i ${probeBed} \
                 -g <(cut -f1,2 ${onekgGenomeFasta}.fai))) | \
awk '{if($13 < 600 &&  $10 != "." ){print $0}}' | \
cut -f7,8,9,10,11,12| sort | \
cat - \
       	<(bedtools sort -i \
                <(bedtools slop \
                 -l 60 \
                 -r -60 \
                 -s \
                 -i ${probeBed} \
                 -g <(cut -f1,2 ${onekgGenomeFasta}.fai))) | \
sort | \
uniq -c  > ${nugeneProbeMetricsDeDupLog}

putFile ${nugeneProbeMetricsLog} 
putFile ${nugeneProbeMetricsDeDupLog}

echo "## "$(date)" ##  $0 Done "
