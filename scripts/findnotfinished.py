#!/usr/bin/env python3
import sys, os, time, subprocess
import pprint
#use findnotfinished.py /path/to/jobsdir

try:
    input_dir = sys.argv[1];
except:
    print('Die cannot open dir')
    exit

started_jobs = []
print("# Getting dir listing...(might take a while...)")
#get the started jobs when no finished is present...this sound iffy and it might be.
for filename in os.listdir(input_dir):
    f = os.path.join(input_dir, filename)
    # checking if it is a file
    #check if started/finished is present...finished????
    if os.path.isfile(f) and f.find(".sh.started") != -1 and not os.path.isfile(f.replace(".started",".finished")):
        projectname=""
        #print(f)
        fh = open(f.replace(".started",""))
        for line in fh:
            if(line[:len("project")] == "project"):
                projectname=line[len("project=\""):-2]
                #print(projectname,f)
        started_jobs.append({"file" : f, "projectname" : projectname})

#os.system("sacct --format=Jobid,jobname,user,State,Elapsed,node,Submit -s r -p -u $USER");

#subprocess.run(["ls", "-l", "/dev/null"])


running_jobs = []
print("# Getting running slurm jobs...")
queue = subprocess.run(["sacct","--format=Jobid,jobname,user,State,Elapsed,node,Submit","-s","r,pd","-p"],stdout=subprocess.PIPE,)
for line in queue.stdout.decode('UTF-8').splitlines(): 
	#print(line)
	psv= line.split("|")
	jobnamefull = psv[1];
	#jobid = jobnamefull.split("_")[-1]
	jobbase = jobnamefull.split("_")[-2:]
	#here a check might be added that the projectname from the bash file also matches jobnamefull.split("_")[:-3]...
	if not jobnamefull == "batch":
		running_jobs.append({"base": "_".join(jobbase),"fullname": jobnamefull})

#pp = pprint.PrettyPrinter()
#pp.pprint(running_jobs)

failed_jobs = {}

print("# Removing running slurm jobs from started list...")
# to get your failed jobs
for job in started_jobs:
	running = False
	#print(job)
	for runningjob in running_jobs:
		#print(runningjob["fullname"][:len(job["projectname"])])
		if job["file"].find(runningjob["base"]+".sh.started") != -1 and runningjob["fullname"][:len(job["projectname"])] == job["projectname"]:
			running=True
	if not running:
		job["file"] =job["file"].strip(".sh.started");
		#print("failed jobs erorr in: " + job.replace(".sh.started",".err"))
		#failed_jobs.append(job);
		jobid = job["file"].split("_")[-1]
		jobbase = "_".join(job["file"].split("_")[:-1])
		if jobbase in failed_jobs:
			failed_jobs[jobbase].append(jobid);
		else:
			failed_jobs[jobbase]=[jobid]

print("\n# Here a prettyish list of all the failed jobs.\n")
for jobbase in failed_jobs.keys():
	if len(failed_jobs[jobbase]) > 1:
		print("failed jobs " + jobbase + "_{" + ",".join(sorted(failed_jobs[jobbase]))+"}.err");
	else:
		#this removes the curly bracktes and the comma for ez copypasting
		print("failed job " + jobbase + "_" + ",".join(sorted(failed_jobs[jobbase]))+".err");
	print("\t\\_consider checking " + jobbase + "_" + sorted(failed_jobs[jobbase])[0] + ".err");
