#MOLGENIS walltime=23:59:00 mem=6gb ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string tableToXlsxMod
#string xlsxDir
#string tableDir

#list nugeneProbeMetricsLog,nugeneProbeMetricsDeDupLog
#string nugeneCNRProbesTable
#string nugeneDedupCNRProbesTable
#string nugeneCNRProbesXlsx
#string nugeneDedupCNRProbesXlsx

alloutputsexist \
"${nugeneCNRProbesTable}" \
"${nugeneCNRProbesXlsx}" \
"${nugeneCNRProbesXlsx}"".probecounts.xlsx" \
"${nugeneDedupCNRProbesTable}" \
"${nugeneDedupCNRProbesXlsx}" \
"${nugeneDedupCNRProbesXlsx}"".probecounts.xlsx" \


echo "## "$(date)" ##  $0 Started "

for file in "${nugeneProbeMetricsLog[@]}" "${nugeneProbeMetricsDeDupLog[@]}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load module
${stage} ${tableToXlsxMod}
${checkStage}

set -o posix
set -o pipefail
set -x
set -e

mkdir -p ${xlsxDir}
mkdir -p ${tableDir}


#############################################################################################
#with dups part

#${addOrReplaceGroupsBam} sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
nugeneCNRTables=($(printf '%s\n' "${nugeneProbeMetricsLog[@]}" | sort -u ))
nugene300bpCountsCNRTables=($(printf '%s.counts300bp.log\n' "${nugeneProbeMetricsLog[@]}" | sort -u ))

#############################################################################################
#advised stuffs from nugene

#Mergetables
cut -f1-6 "${nugene300bpCountsCNRTables[0]}" > "${nugeneCNRProbesTable}"
for i in "${nugene300bpCountsCNRTables[@]}"; do
	(cut -f7-10 $i |perl -wpe 's!([\w_]+)!'"$(basename $i .probemetrics.tsv.counts300bp.log)"'.$1!g if ( $. == 1);' ) |
		paste "${nugeneCNRProbesTable}"  - > "${nugeneCNRProbesTable}"".tmp"
         mv "${nugeneCNRProbesTable}"".tmp" "${nugeneCNRProbesTable}"
done

#convert to xlsx and mv to target file
tableToXlsx.pl \\t "${nugeneCNRProbesTable}"
xlsx="$(echo "${nugeneCNRProbesTable}"| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')"
mv -v "$xlsx" "${nugeneCNRProbesXlsx}"
putFile "${nugeneCNRProbesXlsx}"
#
##Own goodness
#
echo -e "chrom\tstart\tend\tprobe\tstrand" > ${nugeneCNRProbesTable}.probecounts.tsv
cat "${nugeneCNRTables[0]}" | perl -wpe 's/^ *//;s/ /\t/g'| cut -f 2-5,7 >> "${nugeneCNRProbesTable}".probecounts.tsv

for i in "${nugeneCNRTables[@]}"; do
        ((echo "count"; cut -f1 $i) |perl -wpe 's!([\w_]+)!'"$(basename $i .probemetrics.tsv)"'.$1!g if ( $. == 1);' ) |
                paste "${nugeneCNRProbesTable}".probecounts.tsv  - > "${nugeneCNRProbesTable}"".probecounts.tsv.tmp"
         mv "${nugeneCNRProbesTable}"".probecounts.tsv.tmp" "${nugeneCNRProbesTable}"".probecounts.tsv"
done

#convert to xlsx and mv to target file
tableToXlsx.pl \\t "${nugeneCNRProbesTable}"".probecounts.tsv"
xlsx="$(echo "${nugeneCNRProbesTable}"".probecounts.tsv" | perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')"
mv -v "$xlsx" "${nugeneCNRProbesXlsx}"".probecounts.xlsx"
putFile "${nugeneCNRProbesXlsx}"".probecounts.xlsx"

#############################################################################################
#dedup part

#nugeneProbeMetricsDeDupLog
nugeneCNRDedupTables=($(printf '%s\n' "${nugeneProbeMetricsDeDupLog[@]}" | sort -u ))
nugene300bpCountsDedupCNRTables=($(printf '%s.counts300bp.dedup.log\n' "${nugeneProbeMetricsLog[@]}" | sort -u ))

#Mergetables
cut -f1-6 ${nugene300bpCountsDedupCNRTables[0]} > "${nugeneDedupCNRProbesTable}"
for i in "${nugene300bpCountsDedupCNRTables[@]}"; do
        (cut -f7-10 $i |perl -wpe 's!([\w_]+)!'"$(basename $i .probemetrics.tsv.counts300bp.dedup.log)"'.$1!g if ( $. == 1);' ) |
                paste "${nugeneDedupCNRProbesTable}"  - > "${nugeneDedupCNRProbesTable}"".tmp" 
         mv "${nugeneDedupCNRProbesTable}"".tmp" "${nugeneDedupCNRProbesTable}"
done 

#nugeneCNRProbesXlsx
#convert to xlsx and mv to target file
tableToXlsx.pl \\t "${nugeneDedupCNRProbesTable}"
xlsx="$(echo "${nugeneDedupCNRProbesTable}"| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')"
mv -v "$xlsx" "${nugeneDedupCNRProbesXlsx}"

putFile	"${nugeneDedupCNRProbesXlsx}"

#
##Own goodness without pcr duplicates = advised table
#
echo -e "chrom\tstart\tend\tprobe\tstrand" > ${nugeneDedupCNRProbesTable}.probecounts.tsv
cat "${nugeneCNRDedupTables[0]}" | perl -wpe 's/^ *//;s/ /\t/g'| cut -f 2-5,7 >> "${nugeneDedupCNRProbesTable}".probecounts.tsv

for i in "${nugeneCNRDedupTables[@]}"; do
        ((echo "count"; cut -f1 $i) |perl -wpe 's!([\w_]+)!'"$(basename $i .probemetrics.tsv)"'.$1!g if ( $. == 1);' ) |
                paste "${nugeneCNRProbesTable}".probecounts.tsv  - > "${nugeneDedupCNRProbesTable}"".probecounts.tsv.tmp"
         mv "${nugeneDedupCNRProbesTable}"".probecounts.tsv.tmp" "${nugeneDedupCNRProbesTable}"".probecounts.tsv"
done

#convert to xlsx and mv to target file
tableToXlsx.pl \\t "${nugeneDedupCNRProbesTable}"".probecounts.tsv"
xlsx="$(echo "${nugeneDedupCNRProbesTable}"".probecounts.tsv" | perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')"
mv -v "$xlsx" "${nugeneDedupCNRProbesXlsx}"".probecounts.xlsx"

putFile "${nugeneDedupCNRProbesXlsx}"".probecounts.xlsx"

echo "## "$(date)" ##  $0 Done "

