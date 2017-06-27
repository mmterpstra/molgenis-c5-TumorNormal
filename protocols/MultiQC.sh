#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=4

#string project
#string projectDir

#string multiqcMod
#string stage
#string checkStage


#string multiQcHtml

alloutputsexist \
 ${multiQcHtml} \

echo "## "$(date)" Start $0"

#load modules
${stage} ${multiqcMod}

${checkStage}

set -x
set -e


cd ${projectDir}
echo '
snpeff:
    contents: 'SnpEffVersion'
    max_filesize: 1000000
'> multiqc_config.yaml
multiqc ./

putFile ${multiQcHtml}

echo "## "$(date)" Done $0"

