#MOLGENIS walltime=23:59:00 mem=8gb ppn=1

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string cnvlibMod
#string onekgGenomeFasta
#list bqsrBam,bqsrBai
#string targetsList
#string haplotyperVcf
#string haplotyperVcfIdx
#string controlSampleBam
#string controlSampleBai
#string controlSampleBamBai

#string cnvTargetBed
#string cnvDir
#string controlSampleTargetcoverageCnn

echo "## "$(date)" ##  $0 Started "

alloutputsexist \
"${controlSampleTargetcoverageCnn}" \
"${cnvDir}"

for file in "${bqsrBam[@]}" "${bqsrBai[@]}" "${haplotyperVcf}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

${stage} ${cnvlibMod}
${checkStage}

set -x
set -e


if [ `printf '%s\n' "${bqsrBam[@]}" | sort -u | grep -v -c  "$(basename "${controlSampleBam}")"` == 0 ] ; then

	echo "Skipping because no controls"
	touch "${controlSampleTargetcoverageCnn}"
	touch "${cnvDir}"

else
	# sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
	bams=($(printf '%s\n' "${bqsrBam[@]}" | sort -u | grep -v "$(basename "${controlSampleBam}")"))

	#inputs=$(printf ' -I %s ' $(printf '%s\n' ${bams[@]}))

	#cnv.controlsamplename
	mkdir -p ${cnvDir}

	if [ ${#targetsList} -ne 0 ]; then
		grep -v '^@' ${targetsList} | perl -wlane 'print join("\t",($F[0],$F[1]-1,$F[2],$.));' >  "${cnvTargetBed}"
	else
		echo "Error only works on capturing, for now..."
		exit 1
	fi

	cnvkit.py batch \
	 --output-dir "${cnvDir}" \
	 -n ${controlSampleBam} \
	 --method hybrid \
	 --drop-low-coverage \
	 --processes 10 \
	 --fasta "${onekgGenomeFasta}" \
	 --targets "${cnvTargetBed}" \
	 --scatter \
	 --diagram \
	 $(printf ' %s' ${bams[@]})

	normalid="$(basename "${controlSampleBam}" .bam )"

	for cnr in ${cnvDir}/*.cnr; do 
		name="$(basename "$cnr" .cnr)"
		cnvkit.py segment \
		 "${cnvDir}/${name}.cnr" \
		 --normal-id "${normalid}" \
		 --sample-id "${name}" \
		 --vcf "${haplotyperVcf}" \
		 -o "${cnvDir}/${name}.cns"
	
		cnvkit.py scatter \
		 "${cnvDir}/${name}.cnr" \
		 -s "${cnvDir}/${name}.cns" \
		 -o "${cnvDir}/${name}-scatter.pdf" \
	 --normal-id "${normalid}" \
	 --sample-id "${name}" \
	 -m 20 \
	 --vcf "${haplotyperVcf}"
done	
fi 
putFile "${controlSampleTargetcoverageCnn}"
putFile "${cnvDir}"


echo "## "$(date)" ##  $0 Done "
