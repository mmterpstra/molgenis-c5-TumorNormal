cd ../
for i in workflows/workflow*.csv; do
	python scripts/validateworkflow.py $i
done
