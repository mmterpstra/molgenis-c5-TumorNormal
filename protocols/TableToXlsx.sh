#MOLGENIS walltime=23:59:00 mem=1gb ppn=1

#string project


#string inTable
#string outXlsx

module load tableToXlsx/0.1

alloutputsexist \
"${outXlsx}"

getFile ${inTable}

set -x
set -e

tableToXlsx.pl \\t ${inTable}
#just guess the output...
XLSX=$(echo ${inTable}| perl -wpe 's/.txt$|.tsv$|.csv$|.table$/.xlsx/g')

mkdir -p $(basename ${outXlsx})

mv -v $XLSX ${outXlsx}

putFile ${outXlsx}
