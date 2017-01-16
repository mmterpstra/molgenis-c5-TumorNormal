#MOLGENIS nodes=1 ppn=8 mem=4gb walltime=23:59:00

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

set -x
set -e

mkdir -p ${nugeneProbeMetricsDir}

#do bqsr for covariable determination then do print reads for valid bsqrbams
#check the bqsr part and add known variants

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
