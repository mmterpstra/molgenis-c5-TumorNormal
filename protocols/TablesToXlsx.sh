#MOLGENIS walltime=23:59:00 mem=8gb ppn=1 nodes=1 


#string project


#inTable
#string stage
#string tableToXlsxMod

#list indelMnpTable,indelMnpRawTable,snvTable,snvRawTable
#string snvDescrTable
#string indelMnpDescrTable

#outXlsx
#string xlsxDir

${stage} ${tableToXlsxMod}

outXlsx=""

for inTable in "${indelMnpTable[@]}" "${indelMnpRawTable[@]}" "${snvTable[@]}" "${snvRawTable[@]}" "${snvDescrTable}" "${indelMnpDescrTable}"; do 
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
	perl $EBROOTTABLETOXLSX/tableToXlsx.pl \\t $inTable
	xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
	mv -v $xlsx ${xlsxDir}
	putFile ${xlsxDir}/$(basename $xlsx)
done

