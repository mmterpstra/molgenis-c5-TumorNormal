#MOLGENIS nodes=1 ppn=1 mem=7gb walltime=47:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string gatkMod
#string gatkOpt
#string onekgGenomeFasta
#string goldStandardVcf
#string goldStandardVcfIdx

#string oneKgPhase1IndelsVcf
#string oneKgPhase1IndelsVcfIdx

#string dbsnpVcf
#string dbsnpVcfIdx

#string bqsrDir
#list bqsrBam,bqsrBai
#string targetsList
#string dcovDir
#string dcovTsv
#string dcovRefflat

#pseudo from gatk forum (link: http://gatkforums.broadinstitute.org/discussion/3891/best-practices-for-variant-calling-on-rnaseq):
#java -jar GenomeAnalysisTK.jar -T SplitNCigarReads -R ref.fasta -I dedupped.bam -o split.bam -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${dcovTsv}

getFile ${onekgGenomeFasta}
for file in "${bqsrBam[@]}" "${bqsrBai[@]}" "${dbsnpVcf}" "${dbsnpVcfIdx}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

${stage} ${gatkMod}
${checkStage}

set -x
set -e

mkdir -p ${dcovDir}
#input files
# sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n' "${bqsrBam[@]}" | sort -u ))
inputs=$(printf ' -I %s ' $(printf '%s\n' ${bams[@]}))

#do bqsr for covariable determination then do print reads for valid bsqrbams
#check the bqsr part and add known variants

grep '^[^@]' "${targetList}" | perl -wlane 'print join("\t" ,($F[4],$F[4],$F[0],$F[3],$F[1],$F[2],$F[1],$F[1],1,$F[1],$F[2]));'  > "${dcovRefflat}" 

java -Xmx6g -Djava.io.tmpdir="${dcovDir}"  -XX:+UseConcMarkSweepGC  -XX:ParallelGCThreads=1 -jar $EBROOTGATK/GenomeAnalysisTK.jar \
 -R "${onekgGenomeFasta}" \
 -T DepthOfCoverage \
 --omitDepthOutputAtEachBase \
 --countType COUNT_FRAGMENTS \
 --calculateCoverageOverGenes "${dcovRefflat}" \
 --outputFormat 'table' \
 --includeRefNSites \
 --printBaseCounts \
 $inputs \
 --out "${dcovTsv}" \
 -L "${targetsList}" \
 --summaryCoverageThreshold 10 \
 --summaryCoverageThreshold 20 \
 --summaryCoverageThreshold 50 \
 --summaryCoverageThreshold 100 \
 --summaryCoverageThreshold 200 \
 --summaryCoverageThreshold 500 \
 --summaryCoverageThreshold 1000 \
 --summaryCoverageThreshold 2000 \
 --summaryCoverageThreshold 5000 \
 --summaryCoverageThreshold 10000 \



putFile ${dcovTsv}

echo "## "$(date)" ##  $0 Done "
