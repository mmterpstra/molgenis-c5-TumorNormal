#!/usr/bin/perl

use strict;
use warnings;

use Proc::Daemon;
use Proc::PID::File;
use Getopt::Long;
use Log::Log4perl qw(:easy);
use File::Basename;
use Data::Dumper;
our $logger;
main();


sub main {
	#use Proc::Daemon;
	my $subcommand = shift @ARGV || "";

	#cli processing
	my $opts = {
		'use' => "Use:$0 [start|status|kill|restart] options
	Options
		--verbose	toggles verbosity
		--workdir PATH	changes workdir for deamon
		--basename STRING	changes basename for deamon
		--watchlist FILE	list of submit.sh scripts to watch
		--ctype slurm		change the clustertype for now
					only slurm support
		--retry INT		change the retry times
		--unfinished STR	string to match files in submit dir to 
					test for unfinished jobs
		--tofinish STR		string to match files in submit dir to 
					test for jobs to finish
		--finished STR		string to match files in submit dir to 
					test for finished submit.sh.  blocks 
					if finished>=tofinish",
		
		'get' => "",#populated below
		'v' => 0,
		'wd' => './',
		'wl' => 'submit.list',
		'base' => $0,
		'retry' => 3,
		'ctype' => 'slurm',
		'finished' => 'Cleanup_*.finished',
		'tofinish' => 'Cleanup_*.sh',
		'unfinished' => '*.started',
	};
	
	$opts -> {'get'}  = {"verbose"  => \$opts -> {'v'},
	"workdir=s"  => \$opts -> {'wd'},
	"basename=s"  => \$opts -> {'base'},
	"watchlist=s" => \$opts -> {'wl'},
	"ctype=s" => \$opts -> {'ctype'},
	"retry=s" => \$opts -> {'retry'},
	"unfinished=s" => \$opts -> {'unfinished'},
	"tofinish=s" => \$opts -> {'tofinish'},
	"finished=s" => \$opts -> {'finished'}
	};
	
	GetOptions (%{$opts -> {'get'}}) 
	or die("Error in command line arguments\n");
	
	#start logging stuff
	my $logLevel = $INFO;
	$logLevel = $DEBUG if ($opts -> {'v'});
	Log::Log4perl->easy_init(
		{
			level  => $logLevel,
			file   => "STDERR",
			layout => '%d L:%L %p> %m%n'
		},
	);
	$logger = Log::Log4perl::get_logger();

	#init factors
	
	my $daemon = Proc::Daemon->new(
		work_dir => $opts -> {'wd'},
		child_STDOUT => ">>".$opts -> {'base'}."_out.txt",
		child_STDERR => ">>".$opts -> {'base'}."_err.txt",
		pid_file => $opts -> {'wd'}."/".$opts -> {'base'}.".pid"
	);

	if($subcommand eq "start"){
		if (Proc::PID::File -> running(dir=>$opts -> {'wd'},name=>$opts -> {'basename'} )) {
			$logger->info( "$0: Worker already running!!".localtime(time()));
			exit(0);
		}		
		
		my $ChildPID = $daemon->Init;

		unless ( $ChildPID ) {
		    # code executed only by the child ...
			$logger->info("Submit Daemon Checking...");
			my $deamondata = {};
			
			while(1){
				$logger->info("Submit Daemon work");		
				$deamondata = SubmitDaemonWork($deamondata,$opts);
				$logger->info("Submit Daemon Sleep");
				sleep(3600);#should be once every hour?;
			}
			
			$logger->info("Submit Daemon run Ended..");
			
		}

		#$Kid_2_PID = $daemon->Init( { 
		#                work_dir     => '/data/umcg-mterpstra/umcg-oncogenetics/git/molgenis-c5-TumorNormal',
		#                exec_command => 'perl /home/my_script.pl',
		#             } );
		#warn "$0: Succes ";
		#sleep(20);
		#warn "$0: Ended ";
	}elsif($subcommand eq "status"){

		my $pid = $daemon->Status();
		if($pid){		
			$logger->info( "Running with $pid");
		}else {
			$logger->error("Not running with any pid. Return code: $pid");
		}

	}elsif($subcommand eq "kill"){
		my $stopped = $daemon->Kill_Daemon();
		if($stopped){
			$logger->info("sucessfully killed");
		}else{
			$logger->error("failed killing worker return value:$stopped");
		}
	}elsif($subcommand eq "restart"){
		#just kill and restart
		my $stopped = $daemon->Kill_Daemon();
		if($stopped){
			$logger->info("sucessfully killed");
		}else{
			$logger->info("failed killing worker return value:$stopped");
		}
		sleep(1);
		if (Proc::PID::File -> running(dir=>$opts -> {'wd'},name=>$opts -> {'basename'} )) {
			$logger->info( "$0: Worker already running!!".localtime(time()));
			exit(0);
		}		
		
		my $ChildPID = $daemon->Init;

		unless ( $ChildPID ) {
		    # code executed only by the child ...
			$logger->info("Submit Daemon Checking...");
			my $deamondata = {};
			
			while(1){
				$deamondata = SubmitDaemonWork($deamondata,$opts);
			}
			$logger->info("Submit Daemon Sleep");
			sleep(3600);#should be once every hour?;
			$logger->info("Submit Daemon run Ended..");
			
		}

		#$Kid_2_PID = $daemon->Init( { 
		#                work_dir     => '/data/umcg-mterpstra/umcg-oncogenetics/git/molgenis-c5-TumorNormal',
		#                exec_command => 'perl /home/my_script.pl',
		#             } );
		#warn "$0: Succes ";
		#sleep(20);
		#warn "$0: Ended ";
		
	}else{
		$logger->info("invalid subcommand\n" . $opts -> {'use'});
	}
}

sub GetClusterConfig {
	my $self = shift(@_);#	 or $logger->error("ClusterConfig sub error");
	my $opts = shift(@_);#	 or $logger->error("ClusterConfig sub error");
	$self = {
		'queue' => 'regular',
		'ctype' => $opts -> {'ctype'},
		'slurm' => { 
			'jobsubmitcmd' => 'sbatch',
			'queuestatuscmd' => 'squeue -u $USER -o "%i|%P|%q|%j|%u|%t|%M|%R|%S|%p|%c|%m"',
			'queuestatusconversion' => { #covert be like JOBID|PARTITION|QOS|NAME|USER|ST|TIME|NODELIST(REASON)|START_TIME|PRIORITY|MIN_CPUS|MIN_MEMORY
				'NAME' => 'name',
				'JOBID' => 'id',
				'PARTITION' => 'partition',
				'QOS' => 'qos',
				'STATUS' => 'status',
				'USER' => 'user',
				'ST' => 'status',
				'TIME' => 'runtime',
				'NODELIST(REASON)' => 'nodeOrReason',
				'START_TIME' => 'starttime',
				'PRIORITY' => 'prio',
				'MIN_CPUS' => 'jobcpu',
				'MIN_MEMORY' => 'jobmem',
			},
			'runsubmitcmd' => 'set -e && set -x && set -o pipefail && bash ',
			'queuelimitscmd' => 'sacctmgr show qos format=Name%15,Priority,UsageFactor,GrpTRES%30,GrpSubmit,MaxTRESPerUser%30,MaxSubmitJobsPerUser,Preempt%45,MaxWallDurationPerJob',
			
		},
	};
	
	return $self;

};

sub GetProjectsSubmit {
	my $submit = shift @_ or $logger->fatal("no input ".@_);;
	my $projects;
	my $taskname = undef;
	$logger->debug("reading submit.sh '".$submit."'");
	open(my $subin,'<', $submit ) or $logger->fatal("Read error of '".$submit."'!!!\n $!");
	while(not(defined($taskname)) and my $line = <$subin>){
		chomp $line;
		#$logger->debug("Processing line '$line'");
		next if (not($line =~ m/\s*tname=\"\w+"/));
		$logger->debug("Processing line '$line'");
		my $taskdir =  dirname($submit);		
		(undef,$taskname,undef)=split('"',$line);
		my $taskbase = substr($taskname,0,length($taskname)-1);
		$logger->debug("parsing $taskname matched with $taskdir/$taskbase*.sh");
		for my $task (<"$taskdir/$taskbase*.sh">){
			my $project;
			open(my $taskin,'<', $task ) or $logger->fatal("Read error of '".$task."'!!!\n $!");
			$logger->debug("Processing file '$task'");		
			while(not(defined($project)) and my $line = <$taskin>){
				if($line =~ m/^project=/){
					$logger->debug("protocols match on '$line'");
					(undef,$project,undef) = split('"',$line);
					$logger->debug("Processing line '$line'");
					push(@{$projects},$project);
					$logger->debug("Found $project in $task");
				}
			}
		} 
		$logger->debug("parsing $_");
	}
	
	return $projects;
}
sub GetWatchlistConfig {
	my $self = shift(@_);
	my $opts = shift(@_);
		$logger->debug("reading watchlist ".$opts -> {'wl'});
		open(my $wl,'<', $opts -> {'wl'} ) or $logger->fatal("Read error of '".$opts -> {'wl'}."'!!!\n $!");
		while(<$wl>){
			chomp;
			push @{$self -> {'watchlist'}},{'submit' => $_,'projects' => GetProjectsSubmit($_),'retry' => $opts -> {'retry'}};
		}
	return $self;
}
sub UpdateWatchlistStatus{
	my $self =  shift @_ or ($logger->fatal("invalid deamondata input") && die "");

	$self = UpdateQueueStatus($self);
	$self = UpdateSubmitStatus($self);

	
	return $self;
}
sub SubmitNotFinishedAndRemoveFinished {
	my $self =  shift @_ or ($logger->fatal("invalid deamondata input") && die "");	
	my $opts =  shift @_ or ($logger->fatal("invalid opts input") && die "");
	#resubmit when a jobs are inactive and a round of retry is still available and
	# dirname(submit.sh) finished >=  dirname(submit.sh) tofinish 
	my @watchListNew;
	for my $submit (@{$self -> {'watchlist'}}){
		my $submitdir = dirname($submit -> {'submit'});
		my $tofinish = $opts -> {'tofinish'};
		my $finished = $opts -> {'finished'};
		my @tofinishlist=<"$submitdir/$tofinish">;
		my @finishedlist=<"$submitdir/$finished">;
		my $tofinishcount = scalar(@tofinishlist);
		my $finishedcount = scalar(@finishedlist);
		if($submit -> {'activejobcount'} == 0 && 
			$submit -> {'retry'}){
			#
			#$logger->debug("results '".$tofinishcount."'"." '".$finishedcount."'");
			
			if($finishedcount < $tofinishcount){
				$submit -> {'retry'}--;
				my $submitcmd = $self -> {$self -> {'ctype'}} -> {'runsubmitcmd'}.
					$submit -> {'submit'}.'&>/dev/stdout | tail -n 50 ';
				$logger->info("Resubmitting '".$submit -> {'submit'}."'");
				my $ret;
				@{$ret} = CmdRunnerNoBreak($submitcmd);
				$logger->info("Submit results:\n\t'".join("\t",@{$ret})."'");
			}else{
				$logger->info("Submit not needed anymore :\n\t'".Dumper($submit)."'");			
			}
			
			
		}
		#do not add to watchlist if finished
		push(@watchListNew,$submit)if($finishedcount < $tofinishcount);
	}
	@{$self -> {'watchlist'}} = @watchListNew;
	return $self;
}
sub UpdateSubmitStatus{
	my $self =  shift @_ or ($logger->fatal("invalid deamondata input") && die "");
	
	for my $submit (@{$self -> {'watchlist'}}){
		my $count = 0;
		for my $job (@{$self -> {'queuestatus'}}){
			for my $project (@{$submit -> {'projects'}}){
				$count++ if(index($job -> {'name'},$project) == 0);
			}
		}
		$submit -> {'activejobcount'} = $count;
	}	
	return $self;
}
sub UpdateQueueStatus {
	my $self =  shift @_ or ($logger->fatal("invalid deamondata input") && die "");
	
	my $queueres = [];
	#catch for failing if something times out
	while(not(defined($queueres -> [0]) and $queueres -> [0] =~ m/NAME/)){
		@{$queueres} = CmdRunner($self -> { $self -> {'ctype'} } -> {'queuestatuscmd'});
	}
	chomp($queueres -> [0]);
	my $queueheader;@{$queueheader} = split('\|',shift(@{$queueres}));
	for my $queuerow (@{$queueres}){
		my $queueinfo;
		chomp $queuerow;	
		my @vals = split('\|',$queuerow);
		my $i = 0;
		#aaargh this does a map to crate a json like object with header name conversion in the fly. 
		map{	my $val = $_;
			if(defined($self -> {$self -> {'ctype'}} -> {'queuestatusconversion'} -> {$queueheader -> [$i]})){
				$queueinfo -> {$self -> {$self -> {'ctype'}} -> {'queuestatusconversion'} -> {$queueheader -> [$i]}} = $val;
			}else{
				$queueinfo -> {'!!'.$queueheader -> [$i]} = $val;
			};
			$i++;}(@vals);
		push(@{$self -> {'queuestatus'}}, $queueinfo);
	}
	#$logger->fatal("queue results ".Dumper($queueres));
	
	return $self;
}
sub CmdRunner {
    my $ret;
    my $cmd = join(" ",@_);

    $logger->debug(" system call:'". $cmd."'");

    @{$ret} = `($cmd )2>&1`;
    if ($? == -1) {
        $logger->fatal("failed to execute: $!\n");
    }elsif ($? & 127) {
        $logger->fatal( sprintf "child died with signal %d, %s coredump",
         ($? & 127),  ($? & 128) ? 'with' : 'without');
    }elsif ($? != 0) {
        $logger->fatal( sprintf "child died with signal %d, %s coredump",
             ($? & 127),  ($? & 128) ? 'with' : 'without');
    }else {
        $logger->debug( sprintf "child exited with value %d\n", $? >> 8 );
	#        warn localtime( time() ). " [INFO] " . sprintf "child exited with value %d\n", $? >> 8;		
    }
    return @{$ret};
}

sub CmdRunnerNoBreak {
    my $ret;
    my $cmd = join(" ",@_);

    $logger->debug(" system call:'". $cmd."'");

    @{$ret} = `($cmd )2>&1`;
    if ($? == -1) {
        $logger->debug("failed to execute: $!\n");
    }elsif ($? & 127) {
        $logger->debug( sprintf "child died with signal %d, %s coredump",
         ($? & 127),  ($? & 128) ? 'with' : 'without');
    }elsif ($? != 0) {
        $logger->debug( sprintf "child died with signal %d, %s coredump",
             ($? & 127),  ($? & 128) ? 'with' : 'without');
    }else {
        $logger->debug( sprintf "child exited with value %d\n", $? >> 8 );
	#        warn localtime( time() ). " [INFO] " . sprintf "child exited with value %d\n", $? >> 8;		
    }
    return @{$ret};
}

sub SubmitDaemonWork {
	my $self =  shift @_ or ($logger->fatal("invalid deamondata input") && die "");
	my $opts =  shift @_ or ($logger->fatal("invalid option input") && die "");
	$self = GetClusterConfig($self,$opts) if(not(defined($self -> {'ctype'})));
	$self = GetWatchlistConfig($self,$opts) if(not(defined($self -> {'watchlist'})));
	$logger->debug("config dump after GetWatchlistConfig: " . Dumper($self));
	$self = UpdateWatchlistStatus($self);
	$logger->debug("config dump after UpdateJobStatus: " . Dumper($self));
	$self = SubmitNotFinishedAndRemoveFinished($self,$opts);
	return $self;
}
sub main_old {
	# Daemonize
	Proc::Daemon::Init(
		 work_dir => '/data/umcg-mterpstra/umcg-oncogenetics/git/molgenis-c5-TumorNormal',
		child_STDOUT => '>>log.txt',
		child_STDERR => '>>debug.txt');

	# If already running, then exit
	if (Proc::PID::File->running()) {
		warn "$0: already running at ".localtime(time());
		exit(0);
	}
	# Perform initializes here
	warn "$0: init at ".localtime(time()); 
	
	# Enter loop to do work
	while(1) {
		# Do whatcha gotta do
		warn "$0: run stuff at ".localtime(time());
		sleep(2);
		exit 0;
	}
}

