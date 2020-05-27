cd ../
for i in workflows/workflow*.csv; do
	python validateworkflow.py $i
done
