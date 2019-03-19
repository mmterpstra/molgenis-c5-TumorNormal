#MOLGENIS walltime=23:59:00 mem=26gb ppn=2 nodes=1 


#string project


#inTable
#string stage
#string tableToXlsxMod
#string parallelMod
#list indelMnpTable,indelMnpRawTable,indelMnpMinTable,indelMnpMinRawTable,snvTable,snvRawTable,snvMinTable,snvMinRawTable,svTable,svRawTable,svMinTable,svMinRawTable,svDescrTable
#string snvDescrTable
#string indelMnpDescrTable
##string svDescrTable

#outXlsx
#string xlsxDir
#string tableDir

${stage} ${tableToXlsxMod}
${stage} ${parallelMod}


outXlsx=""

#dry run???

for inTable in "${indelMnpRawTable[@]}" "${snvRawTable[@]}"  \
 "${snvDescrTable}" "${indelMnpDescrTable}"  "${svDescrTable}"; do
 xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/_split1.xlsx/g')
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
#                tableToXlsxAsStrings.pl \\t $inMinTable
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
#		tableToXlsxAsStrings.pl \\t $inTable
#		xlsx=$(echo $inTable| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')
#		mv -v $xlsx ${xlsxDir}
#		putFile ${xlsxDir}/$(basename $xlsx)
#	fi
#done


for t in ${tableDir}/*.tsv; do
	descr="description"
	#if contains description then do not split
	if [ -z "${t##*$descr*}" ]; then
		tableToXlsxAsStrings.pl \\t "$t"
		xlsxpart="$(echo $t| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/_split1.xlsx/g')"
		xlsx="$(echo $t| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')"
		mv -v "$xlsx" "${xlsxDir}"
		touch "${xlsxDir}/$(basename $xlsxpart)"
		putFile "${xlsxDir}/$(basename $xlsxpart)"
		
	#if does not contain _split_[0123456789] then split
	elif [ ! -z "${t##*_split_[0123456789]*.tsv}" ]; then
		parallel -a "$t" --header ".*\n" -j 4 --block 100m --pipepart "cat /dev/stdin> $(dirname $t)/$(basename $t .tsv)_split_{#}.tsv";
		#this below might not be safe
		tableToXlsxAsStrings.pl \\t $(dirname $t)/$(basename $t .tsv)_split_*.tsv
		xlsx=$(echo $t| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/_split\*.xlsx/g')
		#the $xlsx part depends on globbing so the files shuold be present of else vague errors occur
		for xlsxtoput in $xlsx; do
			mv -v $xlsxtoput "${xlsxDir}" 
			putFile "${xlsxDir}/$(basename "$xlsxtoput")"
		done

	fi
	echo $t' is already split because it contians the '_split_[0123456789]' part'
done
echo "## "$(date)" ##  $0 Done "

