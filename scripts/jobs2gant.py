#!/usr/bin/env python
import sys
import time
import datetime
import os
import subprocess
from pprint import pprint
from os.path import join

#for root, dirs, files in os.walk('./samplesheets/'):
#	print root, 'has'
#	for fn in files:
#		print join(root,fn)
#		runinfo=getGantInfo(join(root,fn))


#getGanttInfo("test")


def getGanttInfo( str ):
	try:
		stream = os.popen("sacct --format=Jobid,jobname,user,Partition,AllocCPUS,State,MaxRSS,ReqMem,Elapsed,node,Submit -a  -p -u $USER --starttime=$(date --date='Yesterday' --rfc-3339=date)")
		#stream = subprocess.Popen("sacct --format=Jobid,jobname,user,Partition,AllocCPUS,State,MaxRSS,ReqMem,Elapsed,node,Submit -a  -p -u $USER --starttime=$(date --date='Yesterday' --rfc-3339=date)", stdout=PIPE)
		#.read()open(sys.argv[1])
	except:
		print('Fatal error cannot run sacct')
		exit
	
	ganttinfo = []
	try:
		psv_last=[]
		for i,line in enumerate(stream):
			line.rstrip()
			psv=line.split('|') # format like Jobid,jobname,user,Partition,AllocCPUS,State,MaxRSS,ReqMem,Elapsed,node,Submit
			if(i > 1):
				if(psv[1].find('batch') > -1 ):
					print '## ' , i , ' line:', psv, psv_last
					ganttinfo.append({'name':psv_last[1], 'start' : psv[-2], 'duration': psv[-4]})
			else:
				print '## ' , i , ' line:', psv
			#if i == 0: 
			#	continue
			#line=line.rstrip()
			#csv= line.split(",")
			psv_last=psv
		#if csv[0].startswith("#"):
		#	continue
	finally:
		stream.close()
	for step in ganttinfo:
		print ','.join([step['name'],step['start'],step['duration']])
getGanttInfo('test')

##  1  line: JobID|JobName|User|Partition|AllocCPUS|State|MaxRSS|ReqMem|Elapsed|NodeList|Submit|
##  2  line: 3063664|1805_Twist_Ludolf_VariantAnnotation_0|umcg-mterpstra|regular|2|CANCELLED by 50100322||9Gn|00:00:00|None assigned|2018-11-29T10:51:36|
##  3  line: 3063665|1805_Twist_Ludolf_CustTumorNormalAnnotations_0|umcg-mterpstra|regular|1|CANCELLED by 50100322||1Gn|00:00:00|None assigned|2018-11-29T10:51:37|
##  4  line: 3063666|1805_Twist_Ludolf_SelectIndels_0|umcg-mterpstra|regular|1|CANCELLED by 50100322||4Gn|00:00:00|None assigned|2018-11-29T10:51:37|

