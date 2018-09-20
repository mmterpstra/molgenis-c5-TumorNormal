#MOLGENIS walltime=23:59:00 mem=6gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir
#string onekgGenomeFasta
#string tableDir
#string splitTableDir
#string pipelineUtilMod
#string parallelMod
#string tableToXlsxMod

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${splitTableDir}".run

#Load modules
${stage} ${parallelMod}
${stage} ${tableToXlsxMod}
${stage} ${pipelineUtilMod}
${checkStage}

set -x
set -e

mkdir -p ${splitTableDir}
touch "${splitTableDir}".run

for tsv in $(ls ${tableDir}/*{snv,indel}*.tsv| grep -v 'description'); do

	#parallel + split for 1 sample a row

	tsvbase="$(basename $tsv .tsv)"

	parallel -a "$tsv" --header ".*\n" -j 4 --block 10m  --pipepart "cat |VcfTableExportOneVariantPerSample.pl /dev/stdin>  ${splitTableDir}$(basename $tsv .tsv)_split_{#}.tsv"
	tableToXlsxAsStrings.pl \\t ${splitTableDir}$(basename $tsv .tsv)_split_*.tsv
	
done

putFile "${splitTableDir}".run

echo "## "$(date)" ##  $0 Done "
