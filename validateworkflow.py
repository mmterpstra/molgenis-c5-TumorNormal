#!/usr/bin/env python
import sys
import time

#use workflow
try:
    workflow = open(sys.argv[1])
except:
    print('Die cannot open file' + sys.argv[1])
    exit


def info(info):
  print >> sys.stderr, "## %s ## INFO ## %s"  % (time.asctime(),info)

def errornofail(error):
  print >> sys.stderr, "## %s ## ERROR ## %s"  % (time.asctime(),error)


def error(error):
  print >> sys.stderr, "## %s ## ERROR ## %s"  % (time.asctime(),error)
  exit(1)

def checkprotocol(protocolfile,parameterseen):
    try:
        protocol = open(protocolfile)
    except:
	print('Die cannot open file ' + protocolfile)
        exit
    try:
        for i, line in enumerate(protocol):
            line = line.rstrip()
            if not(line.startswith("#list") or line.startswith("#string")):
                continue
            ssv = line.split(" ")
            csv = ssv[1].split(",")
            for val in csv:
                if(val in parameterseen):
                    parameterseen[val]+=1
    finally:
	protocol.close()

def checkparameterseen(parameterseen,protocol):
    fail=0
    for key in parameterseen.keys():
        if(parameterseen[key] < 1):
            errornofail("Parameter '" + key + "' not in protocol file "+ protocol)
            fail=1
    if(fail == 1):
        exit(1)


info("Analysing workflow file " + sys.argv[1])

protocolfiles = []

try:
    steps = {}
    for i, line in enumerate(workflow):
        if i == 0: 
            continue
        line=line.rstrip()
        csv= line.split(",")
	if csv[0].startswith("#"):
       	    continue
        if csv[0] in steps:
            steps[csv[0]]=steps[csv[0]]+1
        else:
            steps[csv[0]]=1
	#protocolfiles.append(csv[1])
        #print csv[0]
        #print("node "+ csv[0])
        remap=csv[2].split(";")
        #print edges
        parameterseen = {}
        for element in remap:
            element.rstrip()
            if("=" in element and  element != ""):
                parameterseen[element.split("=")[0]]=0
        checkprotocol(csv[1],parameterseen)
        checkparameterseen(parameterseen,csv[1])
finally:
    workflow.close()
    
#for parameterfile in sys.argv[2::]:
#    info('processing ' + parameterfile)
#    try:
#        parameters = open(parameterfile)
#    except:
#        print('Die cannot open file ' + parameterfile)
#        exit
#    try:
#        for i, line in enumerate(parameters):
#            line = line.rstrip()
#            csv = line.split(",")
#            if(csv[0] in parameterseen):
#                parameterseen[csv[0]]=parameterseen[csv[0]]+1
#    finally:
#        parameters.close()
