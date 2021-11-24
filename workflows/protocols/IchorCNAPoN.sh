#MOLGENIS nodes=1 ppn=1 mem=10gb walltime=23:59:00

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string ichorcnaMod
#string ichorcnaChromosomes
#string onekgGenomeFasta
#list controlSampleBam
#string projectDir

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
 ${projectDir}/ichorCNAPoN/normal.txt \

${stage} ${ichorcnaMod} 
${checkStage}


set -x
set -e

mkdir -p ${projectDir}/ichorCNAPoN/

for file in "${controlSampleBam[@]}" "${onekgGenomeFasta}"; do
        echo "getFile file='$file'"
        getFile $file
done

# sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n' "${controlSampleBam[@]}" | sort -u ))

inputs=$(printf ' -I %s '  ${bams[@]})

#printf '%s\n'  ${bams[@]} > ${ichorcnaDir}/PoN/normal.wig
echo "">  ${projectDir}/ichorCNAPoN/normal.txt

for bam in "${bams[@]}"; do
	window=500000
	wig="${projectDir}/ichorCNAPoN/$(basename $bam .bam).${window}b.wig"
	readCounter\
		--window $window \
		--quality 20 \
		-chromosome $(echo "${ichorcnaChromosomes}"| perl -wpe 's/\t/,/g') \
		"${bam}" > "${wig}"
	echo "${wig}" >> ${projectDir}/ichorCNAPoN/normal.txt
done

createPanelOfNormals.R \
	--filelist ${projectDir}/ichorCNAPoN/normal.txt \
	--gcWig ${onekgGenomeFasta}.500000b.gc.wig \
	--mapWig $EBROOTRMINBUNDLEMINICHORCNA/ichorCNA/extdata/${mapability500kbWig} \
	--centromere $EBROOTRMINBUNDLEMINICHORCNA/ichorCNA/extdata/GRCh38.GCA_000001405.2_centromere_acen.txt \
	--genomeBuild="hg38" \
	--genomeStyle="NCBI" \
	--outfile  ${projectDir}/ichorCNAPoN/panelofnormals_${window}b


putFile  ${projectDir}/ichorCNAPoN//normal.txt


echo "## "$(date)" ##  $0 Done "
