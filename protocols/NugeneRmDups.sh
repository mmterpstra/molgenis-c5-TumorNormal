#MOLGENIS walltime=23:59:00 mem=4gb nodes=1 ppn=1

#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string WORKDIR
#string projectDir

#string samtoolsMod
#string bwaSam 
#string sampleName
#string sequencer
#string seqType
#string sequencerId
#string flowcellId
#string run
#string lane
#string barcode
#string samplePrep
#string internalId
#string nugeneDir
#string nugeneTool
#string nugeneOutputPrefix
#string reads3FqGz
#string reads1FqGz


alloutputsexist \
 ${nugeneOutputPrefix}_n6dupsRemoved_sorted.bam 
# ${addOrReplaceGroupsBai}

echo "## "$(date)" ##  $0 Started "

set -e
set -x

getFile ${bwaSam}


${stage} ${samtoolsMod}
${checkStage}


mkdir -p ${nugeneDir}

echo "## "$(date)" Start $0"


if [ ${#reads3FqGz} -eq 0 ]; then

	getFile ${reads1FqGz}
	
	echo "barcode in tile"
	
	#rewrite gzipped this:
	#@M01277:343:000000000-ADBC0:1:1101:17238:1303 1:N:0:0#
	#CTGCTGATAATGAAAATGATGACTCTGTCTCATATGATCACTTTATAGGTTTGCCTCCTTTTTATGAAACATCTTTCACACACCCCTCCTTTTTCTGCTTCATTTCAGTGTCCATCAATCCATTCGCAATTTCATAATCTTCTTTCTGTT
	#+
	#AC-AC9-C--C,,,,,C,,C,,CEEE,C@CF,,,<,,<,,;CEF,C,,,<CE,;;CCCEE,,;,C,,,,;,CCCFE<,<,;,,66866,,96,:,,,,,:9,<A@A,,,,<55,95,,::9,,:,,,,+,::9,,,,:5A@9AAFEB,99
	
	#to this:
	#@M01277:343:000000000-ADBC0:1:1101:17238:1303 1:N:0:0
	#TCGGATTCCTGACG
	#+
	#==============
	
		
	gzip -dc ${reads1FqGz} | perl -wpe 'BEGIN{my $len=0;};if($.%4==1){ s/ ([ATCGN]{8,}$)/\n$1/g ; $len = length($1); $_.="+\n"."=" x $len ."\n";}else{$_ = ""}'> ${nugeneDir}/$(basename ${reads1FqGz} .gz)

	cd $(dirname ${nugeneTool})

	bash ${nugeneTool} -r ${bwaSam} ${nugeneDir}/$(basename ${reads1FqGz} .gz) ${nugeneOutputPrefix}

	rm -v ${nugeneDir}/$(basename ${reads1FqGz} .gz)
	
else

	getFile ${reads3FqGz}
	
	echo "barcode in read"
	
	gzip -dc ${reads3FqGz} > ${nugeneDir}/$(basename ${reads3FqGz} .gz)

	cd $(dirname ${nugeneTool})

	bash ${nugeneTool} -r ${bwaSam} ${nugeneDir}/$(basename ${reads3FqGz} .gz) ${nugeneOutputPrefix}

	rm -v ${nugeneDir}/$(basename ${reads3FqGz} .gz)
fi

putFile ${nugeneOutputPrefix}_n6dupsRemoved_sorted.bam

echo "## "$(date)" ##  $0 Done "
