#MOLGENIS walltime=23:59:00 mem=26gb ppn=2 nodes=1 


#string project


#inTable
#string stage
#string tableToXlsxMod

#list indelMnpTable,indelMnpRawTable,indelMnpMinTable,indelMnpMinRawTable,snvTable,snvRawTable,snvMinTable,snvMinRawTable,svTable,svRawTable,svMinTable,svMinRawTable,svDescrTable
#string snvDescrTable
#string indelMnpDescrTable
##string svDescrTable

#outXlsx
#string xlsxDir
#string tableDir

${stage} ${tableToXlsxMod}

outXlsx=""

#dry run???

for inTable in "${indelMnpRawTable[@]}" "${snvRawTable[@]}"  \
 "${snvDescrTable}" "${indelMnpDescrTable}"  "${svDescrTable}"; do
 xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
 outXlsx="$outXlsx ${xlsxDir}/"$(basename $xlsx)
done

#for inTable in "${indelMnpTable[@]}" "${indelMnpRawTable[@]}" "${indelMnpMinTable[@]}" "${indelMnpMinRawTable[@]}"\
# "${snvTable[@]}" "${snvRawTable[@]}" "${snvMinTable[@]}" "${snvMinRawTable[@]}" \
# "${svTable[@]}" "${svRawTable[@]}" "${svMinTable[@]}" "${svMinRawTable[@]}" \
# "${snvDescrTable}" "${indelMnpDescrTable}"  "${svDescrTable}"; do
# xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
# outXlsx="$outXlsx ${xlsxDir}/"$(basename $xlsx)
#done

echo "output in the following files '$outXlsx'"

#if the last file is present assume all present
alloutputsexist \
"$outXlsx"

set -x
set -e


mkdir -p "${xlsxDir}"
export TMPDIR="${xlsxDir}/tmp/"
mkdir -p "${xlsxDir}/tmp/"

#for memory issues first export the min and small tables to xlsx
#for inMinTable in  "${indelMnpMinTable[@]}" "${indelMnpMinRawTable[@]}" \
#		 "${snvMinTable[@]}" "${snvMinRawTable[@]}" "${svMinTable[@]}" \
#		 "${svMinRawTable[@]}" "${snvDescrTable}" "${indelMnpDescrTable}" \
#		 "${svDescrTable[@]}"; do 
#	if [ -f $inMinTable ]; then
#                echo "getFile file='$inMinTable'"
#                getFile $inMinTable
#                #just guess the output...
#                perl $EBROOTTABLETOXLSX/tableToXlsxAsStrings.pl \\t $inMinTable
#                xlsx=$(echo $inMinTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
#                mv -v $xlsx ${xlsxDir}
#                putFile ${xlsxDir}/$(basename $xlsx)
#        fi
#
#done

#then the large tables
#for inTable in "${indelMnpTable[@]}" "${indelMnpRawTable[@]}" \
#		 "${snvTable[@]}" "${snvRawTable[@]}" \
#		 "${svTable[@]}" "${svRawTable[@]}"; do
#
#	if [ -f $inTable ]; then
#		echo "getFile file='$inTable'"
#		getFile $inTable
#		#just guess the output...
#		perl $EBROOTTABLETOXLSX/tableToXlsxAsStrings.pl \\t $inTable
#		xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
#		mv -v $xlsx ${xlsxDir}
#		putFile ${xlsxDir}/$(basename $xlsx)
#	fi
#done


for t in ${tableDir}/*.tsv; do
	$EBROOTPERL/bin/perl $EBROOTTABLETOXLSX/tableToXlsxAsStrings.pl \\t $t;
	xlsx=$(echo $t| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
	mv -v $xlsx ${xlsxDir}
	putFile ${xlsxDir}/$(basename $xlsx)
done
