#!/usr/bin/env python3
import sys
import time
try:
    input_file = open(sys.argv[1])
except:
    print('Takes a workflow file as first argument and prints a dotfile to stdout. Die cannot open file')
    exit(1)


print("digraph " + sys.argv[1].strip(".csv").split('/')[-1] + " {")

try:
    for i, line in enumerate(input_file):
        if i == 0: 
            continue
        line=line.rstrip()
        csv= line.split(",")
        if csv[0].startswith("#"):
       	    continue
        #print csv[0]
        #print("node "+ csv[0])
        remap=csv[2].split(";")
        #print edges
        for element in remap:
            #element.rstrip()
            if("=" not in element and  element != ""):
                print("\t"+ element+" -> " + csv[0])
finally:
    input_file.close()

print("}")

def info(info):
    print("## %s ## INFO ## %s"  % (time.asctime(),info), file=sys.stderr)

info(str(i+1) + " line(s) printed.")

