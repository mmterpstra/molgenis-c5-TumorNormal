#MOLGENIS walltime=23:59:00 mem=6gb ppn=4

#string project


#Parameter mapping  #why not string foo,bar? instead of string foo\nstring bar
#string stage
#string checkStage
#string projectDir

#string tableToXlsxMod
#string xlsxDir
#string tableDir

#list htseqTsv

#string htseqTable
#string htseqXlsx


alloutputsexist \
"${htseqTable}" \
"${htseqXlsx}"

echo "## "$(date)" ##  $0 Started "

for file in "${htseqTsv[@]}" ; do
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

#${addOrReplaceGroupsBam} sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
tsvs=($(printf '%s\n' "${htseqTsv[@]}" | sort -u ))
#inputs=$(printf 'INPUT=%s ' $(printf '%s\n' ${tsvs[@]}))

mkdir -p ${xlsxDir}
mkdir -p ${tableDir}

#
echo -n "" > ${htseqTable}.tmp;
for i in $(ls ${tsvs[@]}); do
	(echo -e $(dirname $i)'.'$(basename $i .tsv)"\t";\
		cut -f1,2 $i) | \
	 paste ${htseqTable}.tmp  - > ${htseqTable}.tmp2
	mv ${htseqTable}.tmp2 ${htseqTable}.tmp
done
#
perl -F\\t -wlane 'my @t;if($. == 1){push @t, $F[0];for my $IDX (1..(scalar(@F)-1)){push(@t,$F[$IDX]) if($IDX % 2 == 1 )};}else{push @t, $F[1]; for my $IDX (1..(scalar(@F)-1)){push(@t,$F[$IDX]) if($IDX % 2 == 0 );}} print join("\t",@t);' ${htseqTable}.tmp > ${htseqTable}

perl $EBROOTTABLETOXLSX/tableToXlsx.pl \\t ${htseqTable}
xlsx=$(echo ${htseqTable}| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
mv -v $xlsx ${htseqXlsx}


putFile ${htseqTable}
putFile ${htseqXlsx}

echo "## "$(date)" ##  $0 Done "
