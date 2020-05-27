#!/bin/bash
set -e
set -o pipefail


for i in  ../workflows/protocols/*.sh; do
	>&2 echo  "## "$(date)" ## $0 ## sanity checking $i"
	bash -n "$i"
done

