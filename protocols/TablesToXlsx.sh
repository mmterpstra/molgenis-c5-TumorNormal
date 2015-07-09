#MOLGENIS walltime=23:59:00 mem=1gb ppn=1

#inTable
#string indelMnpTable
#string indelMnpRawTable
#string snvTable
#string snvRawTable
#string snvDescrTable
#string indelMnpDescrTable

#outXlsx
#string xlsxDir

module load tableToXlsx/0.1

outXlsx=""

for inTable in "${indelMnpTable}" "${indelMnpRawTable}" "${snvTable}" "${snvRawTable}" "${snvDescrTable}" "${indelMnpDescrTable}"; do 
	xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
	outXlsx="$outXlsx ${xlsxDir}/"$(basename $xlsx)
done

echo "output in the following files '$outXlsx'"

alloutputsexist \
"$outXlsx" 

set -x
set -e

mkdir -p ${xlsxDir}

for inTable in "${indelMnpTable}" "${indelMnpRawTable}" "${snvTable}" "${snvRawTable}" "${snvDescrTable}" "${indelMnpDescrTable}"; do
	echo "getFile file='$inTable'"
	getFile $inTable
	#just guess the output...
	perl $TABTOXLSX_HOME/tableToXlsx.pl \\t $inTable
	xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
	mv -v $xlsx ${xlsxDir}
	putFile ${xlsxDir}/$(basename $xlsx)
done

