cd ../
for i in workflow*.csv; do
	python validateworkflow.py $i
done
