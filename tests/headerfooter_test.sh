#!/bin/bash
set -e
set -o pipefail


for i in  ../templates/compute/v1*/*/*ftl; do
	>&2 echo  "## "$(date)" ## $0 ## sanity checking $i"	
	#Freemarker purge then syntax check
	perl -wpe 's!<#.*?>|</#.*?>!!g' --  "$i" | bash -n 
done

