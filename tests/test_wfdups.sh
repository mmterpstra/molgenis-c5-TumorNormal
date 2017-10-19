set -e;
set -x;
for wf in $(ls ../workflow*.csv); do 
	if [ $(grep -v '^#' $wf |sort -t, | wc -l) -eq $(grep -v '^#' $wf |sort -k1,1 -u -t, | wc -l) ]; then 
		echo "## INFO ## No dups in "$wf;
	else 
		echo "## ERROR ## Dups in $wf file detected. Conflicting record shown below."; 
		diff <(grep -v '^#' $wf |sort -t,) <(grep -v '^#' $wf |sort -k1,1 -u -t,)| perl -wpe 's/^/## ERROR ##/g'; 
		exit 1;
	fi;
done

