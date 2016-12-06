#MOLGENIS walltime=23:59:00 mem=26gb ppn=1 nodes=1 


#string project


#inTable
#string stage
#string tableToXlsxMod

#list indelMnpTable,indelMnpRawTable,indelMnpMinTable,indelMnpMinRawTable,snvTable,snvRawTable,snvMinTable,snvMinRawTable,svTable,svRawTable,svMinTable,svMinRawTable
#string snvDescrTable
#string indelMnpDescrTable
#string svDescrTable

#outXlsx
#string xlsxDir

${stage} ${tableToXlsxMod}

outXlsx=""

#dry run???
for inTable in "${indelMnpTable[@]}" "${indelMnpRawTable[@]}" "${indelMnpMinTable[@]}" "${indelMnpMinRawTable[@]}"\
               "${snvTable[@]}" "${snvRawTable[@]}" "${snvMinTable[@]}" "${snvMinRawTable[@]}" \
               "${svTable[@]}" "${svRawTable[@]}" "${svMinTable[@]}" "${svMinRawTable[@]}" \
               "${snvDescrTable}" "${indelMnpDescrTable}"  "${svDescrTable}"; do
	xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
	outXlsx="$outXlsx ${xlsxDir}/"$(basename $xlsx)
done

echo "output in the following files '$outXlsx'"

#if the last file is present assume all present
alloutputsexist \
"$outXlsx"

set -x
set -e

mkdir -p ${xlsxDir}

for inTable in "${indelMnpTable[@]}" "${indelMnpRawTable[@]}" "${indelMnpMinTable[@]}" "${indelMnpMinRawTable[@]}"\
               "${snvTable[@]}" "${snvRawTable[@]}" "${snvMinTable[@]}" "${snvMinRawTable[@]}" \
               "${svTable[@]}" "${svRawTable[@]}" "${svMinTable[@]}" "${svMinRawTable[@]}" \
               "${snvDescrTable}" "${indelMnpDescrTable}"  "${svDescrTable}"; do

	echo "getFile file='$inTable'"
	getFile $inTable
	#just guess the output...
	perl $EBROOTTABLETOXLSX/tableToXlsx.pl \\t $inTable
	xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
	mv -v $xlsx ${xlsxDir}
	putFile ${xlsxDir}/$(basename $xlsx)
done

