#MOLGENIS walltime=143:59:00 mem=30gb ppn=2

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string onekgGenomeFasta
#string markDuplicatesBam
#string markDuplicatesBai

#string samtoolsMod
#string htslibMod
#string mantaMod
#string mantaConfigType
#string mantaDir
#string mantaRunDir
#string mantaVcf
#string mantaVcfIdx

alloutputsexist \
"${mantaRunDir}" \
"${mantaVcf}"

echo "## "$(date)" ##  $0 Started "


for file in "${onekgGenomeFasta}" "${markDuplicatesBam[@]}" "${markDuplicatesBai[@]}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load module
#${stage} ${samtoolsMod} ${htslibMod}
${stage} ${mantaMod}
${checkStage}

set -x
set -e

# sort unique and print like '--bam=file1.bam --bam=file2.bam '
bamsu=($(printf '%s\n' "${markDuplicatesBam[@]}" | sort -u ))

declare -a bams

mkdir -p ${mantaDir}
mkdir -p ${mantaRunDir}


for bam in "${bamsu[@]}" ; do
	(
		${stage} ${samtoolsMod} ${htslibMod}
		
		if [ $(samtools view -c -f 1  $bam) -ge 1 ]; then
			#bams+=($bam)
			nohardclipbam=${mantaRunDir}/$(basename $bam)
			samtools view -F 1024 -h $bam | perl -wlane 'if(not(m/^[@]/)&& defined($F[5])){$F[5] =~ s/\d*H//g;print join("\t",@F);}else{print $_;}' | samtools view -Sb > $nohardclipbam
			samtools index $nohardclipbam
			bams+=($nohardclipbam)
		else
			echo "SE, Skipped "$bam"'"
		fi;
	)
done

if [ ${#bams[*]} -ge 1 ]; then
	
	
	inputs=$(printf ' --bam=%s ' $(printf '%s\n' ${bams[@]}))

	mkdir -p ${mantaDir}
	mkdir -p ${mantaRunDir}
	#pseudo: 
	#configManta.py --bam=FILE --exome --referenceFasta=FILE --runDir=DIR 
	#python ${mantaDir}/runWorkflow.py -m local -j 1 -g 20
	configManta.py \
	 $inputs \
	 ${mantaConfigType} \
	 --referenceFasta=${onekgGenomeFasta} \
	 --runDir=${mantaRunDir} \

	#python ${mantaRunDir}/runWorkflow.py \
	# -m local \
	# -j 1 \
	# -g 20
	python ${mantaRunDir}/runWorkflow.py \
         -m local \
         -j 1 \

else
	echo "Manta sv detection skipped because no PE reads present in bamfiles"
	mkdir -p $(dirname ${mantaVcf})
	touch ${mantaVcf}
	(${stage} ${samtoolsMod} ${htslibMod}
		(cat << EOF
##fileformat=VCFv4.1
##fileDate=20170101
##source=GenerateSVCandidates 0.29.5 Dummy file
##reference=file:///data/umcg-mterpstra/apps/data/ftp.broadinstitute.org/bundle/2.8/b37/human_g1k_v37_decoy.fasta
##contig=<ID=1,length=249250621>
##contig=<ID=2,length=243199373>
##contig=<ID=3,length=198022430>
##contig=<ID=4,length=191154276>
##contig=<ID=5,length=180915260>
##contig=<ID=6,length=171115067>
##contig=<ID=7,length=159138663>
##contig=<ID=8,length=146364022>
##contig=<ID=9,length=141213431>
##contig=<ID=10,length=135534747>
##contig=<ID=11,length=135006516>
##contig=<ID=12,length=133851895>
##contig=<ID=13,length=115169878>
##contig=<ID=14,length=107349540>
##contig=<ID=15,length=102531392>
##contig=<ID=16,length=90354753>
##contig=<ID=17,length=81195210>
##contig=<ID=18,length=78077248>
##contig=<ID=19,length=59128983>
##contig=<ID=20,length=63025520>
##contig=<ID=21,length=48129895>
##contig=<ID=22,length=51304566>
##contig=<ID=X,length=155270560>
##contig=<ID=Y,length=59373566>
##contig=<ID=MT,length=16569>
##contig=<ID=GL000207.1,length=4262>
##contig=<ID=GL000226.1,length=15008>
##contig=<ID=GL000229.1,length=19913>
##contig=<ID=GL000231.1,length=27386>
##contig=<ID=GL000210.1,length=27682>
##contig=<ID=GL000239.1,length=33824>
##contig=<ID=GL000235.1,length=34474>
##contig=<ID=GL000201.1,length=36148>
##contig=<ID=GL000247.1,length=36422>
##contig=<ID=GL000245.1,length=36651>
##contig=<ID=GL000197.1,length=37175>
##contig=<ID=GL000203.1,length=37498>
##contig=<ID=GL000246.1,length=38154>
##contig=<ID=GL000249.1,length=38502>
##contig=<ID=GL000196.1,length=38914>
##contig=<ID=GL000248.1,length=39786>
##contig=<ID=GL000244.1,length=39929>
##contig=<ID=GL000238.1,length=39939>
##contig=<ID=GL000202.1,length=40103>
##contig=<ID=GL000234.1,length=40531>
##contig=<ID=GL000232.1,length=40652>
##contig=<ID=GL000206.1,length=41001>
##contig=<ID=GL000240.1,length=41933>
##contig=<ID=GL000236.1,length=41934>
##contig=<ID=GL000241.1,length=42152>
##contig=<ID=GL000243.1,length=43341>
##contig=<ID=GL000242.1,length=43523>
##contig=<ID=GL000230.1,length=43691>
##contig=<ID=GL000237.1,length=45867>
##contig=<ID=GL000233.1,length=45941>
##contig=<ID=GL000204.1,length=81310>
##contig=<ID=GL000198.1,length=90085>
##contig=<ID=GL000208.1,length=92689>
##contig=<ID=GL000191.1,length=106433>
##contig=<ID=GL000227.1,length=128374>
##contig=<ID=GL000228.1,length=129120>
##contig=<ID=GL000214.1,length=137718>
##contig=<ID=GL000221.1,length=155397>
##contig=<ID=GL000209.1,length=159169>
##contig=<ID=GL000218.1,length=161147>
##contig=<ID=GL000220.1,length=161802>
##contig=<ID=GL000213.1,length=164239>
##contig=<ID=GL000211.1,length=166566>
##contig=<ID=GL000199.1,length=169874>
##contig=<ID=GL000217.1,length=172149>
##contig=<ID=GL000216.1,length=172294>
##contig=<ID=GL000215.1,length=172545>
##contig=<ID=GL000205.1,length=174588>
##contig=<ID=GL000219.1,length=179198>
##contig=<ID=GL000224.1,length=179693>
##contig=<ID=GL000223.1,length=180455>
##contig=<ID=GL000195.1,length=182896>
##contig=<ID=GL000212.1,length=186858>
##contig=<ID=GL000222.1,length=186861>
##contig=<ID=GL000200.1,length=187035>
##contig=<ID=GL000193.1,length=189789>
##contig=<ID=GL000194.1,length=191469>
##contig=<ID=GL000225.1,length=211173>
##contig=<ID=GL000192.1,length=547496>
##contig=<ID=NC_007605,length=171823>
##contig=<ID=hs37d5,length=35477943>
##INFO=<ID=IMPRECISE,Number=0,Type=Flag,Description="Imprecise structural variation">
##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">
##INFO=<ID=SVLEN,Number=.,Type=Integer,Description="Difference in length between REF and ALT alleles">
##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the variant described in this record">
##INFO=<ID=CIPOS,Number=2,Type=Integer,Description="Confidence interval around POS">
##INFO=<ID=CIEND,Number=2,Type=Integer,Description="Confidence interval around END">
##INFO=<ID=CIGAR,Number=A,Type=String,Description="CIGAR alignment for each alternate indel allele">
##INFO=<ID=MATEID,Number=.,Type=String,Description="ID of mate breakend">
##INFO=<ID=EVENT,Number=1,Type=String,Description="ID of event associated to breakend">
##INFO=<ID=HOMLEN,Number=.,Type=Integer,Description="Length of base pair identical homology at event breakpoints">
##INFO=<ID=HOMSEQ,Number=.,Type=String,Description="Sequence of base pair identical homology at event breakpoints">
##INFO=<ID=SVINSLEN,Number=.,Type=Integer,Description="Length of insertion">
##INFO=<ID=SVINSSEQ,Number=.,Type=String,Description="Sequence of insertion">
##INFO=<ID=LEFT_SVINSSEQ,Number=.,Type=String,Description="Known left side of insertion for an insertion of unknown length">
##INFO=<ID=RIGHT_SVINSSEQ,Number=.,Type=String,Description="Known right side of insertion for an insertion of unknown length">
##INFO=<ID=INV3,Number=0,Type=Flag,Description="Inversion breakends open 3' of reported location">
##INFO=<ID=INV5,Number=0,Type=Flag,Description="Inversion breakends open 5' of reported location">
##INFO=<ID=BND_DEPTH,Number=1,Type=Integer,Description="Read depth at local translocation breakend">
##INFO=<ID=MATE_BND_DEPTH,Number=1,Type=Integer,Description="Read depth at remote translocation mate breakend">
##INFO=<ID=JUNCTION_QUAL,Number=1,Type=Integer,Description="If the SV junction is part of an EVENT (ie. a multi-adjacency variant), this field provides the QUAL value for the adjacency in question only">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=FT,Number=1,Type=String,Description="Sample filter, 'PASS' indicates that all filters have passed for this sample">
##FORMAT=<ID=GQ,Number=1,Type=Float,Description="Genotype Quality">
##FORMAT=<ID=PL,Number=G,Type=Integer,Description="Normalized, Phred-scaled likelihoods for genotypes as defined in the VCF specification">
##FORMAT=<ID=PR,Number=.,Type=Integer,Description="Spanning paired-read support for the ref and alt alleles in the order listed">
##FORMAT=<ID=SR,Number=.,Type=Integer,Description="Split reads for the ref and alt alleles in the order listed, for reads where P(allele|read)>0.999">
##FILTER=<ID=Ploidy,Description="For DEL & DUP variants, the genotypes of overlapping variants (with similar size) are inconsistent with diploid expectation">
##FILTER=<ID=MaxMQ0Frac,Description="For a small variant (<1000 bases), the fraction of reads in all samples with MAPQ0 around either breakend exceeds 0.4">
##FILTER=<ID=NoPairSupport,Description="For variants significantly larger than the paired read fragment size, no paired reads support the alternate allele in any sample.">
##FILTER=<ID=MinQUAL,Description="QUAL score is less than 20">
##FILTER=<ID=MinGQ,Description="GQ score is less than 15 (filter applied at sample level and record level if all samples are filtered)">
##ALT=<ID=BND,Description="Translocation Breakend">
##ALT=<ID=INV,Description="Inversion">
##ALT=<ID=DEL,Description="Deletion">
##ALT=<ID=INS,Description="Insertion">
##ALT=<ID=DUP:TANDEM,Description="Tandem Duplication">
##cmdline=/data/umcg-mterpstra/apps/software/manta/0.29.5-foss-2016a/bin/configManta.py --bam=Dummy.bam --exome --referenceFasta=/data/umcg-mterpstra/apps/data//ftp.broadinstitute.org/bundle/2.8/b37//human_g1k_v37_decoy.fasta --runDir=Dummy/Dir/
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT'
EOF
		) | bgzip > ${mantaVcf}
	)
	#touch ${mantaVcfIdx}
	touch ${mantaVcf}.pefail
fi

putFile ${mantaVcf}
#putFile ${mantaVcfIdx}

echo "## "$(date)" ##  $0 Done "
