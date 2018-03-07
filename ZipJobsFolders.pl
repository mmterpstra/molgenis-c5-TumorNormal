#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
my $use = "$0 projectfolder

zips everyfolder named jobs starting from projectfolder and mtime +2 or so
";

my $find="find ".$ARGV[0]." -name jobs -type d -mtime +2 ";
#my $jobsfolders= CmdRunner($find);


open(my $find_fh, "-|", $find);

while(my $jobfolder = <$find_fh>){
	warn Dumper($jobfolder)." ";
	chomp $jobfolder;
	my $zip = "cd $jobfolder/../ && zip jobs.zip -r -m -u jobs/";
	CmdRunner($zip);
	#my $rm = "rm -rv $jobfolder";
	#CmdRunner($rm);
}
close $find_fh or warn $! ? "Error closing sort pipe: $!"
	: "Exit status $? from sort";


sub CmdRunner {
    my $ret;
    my $cmd = join(" ",@_);

    warn localtime( time() ). " [INFO] system call:'". $cmd."'.\n";

    @{$ret} = `set -e -o pipefail && ($cmd )`;
    if ($? == -1) {
        die localtime( time() ). " [ERROR] failed to execute: $!\n";
    }elsif ($? & 127) {
	warn Dumper($ret);
        die localtime( time() ). " [ERROR] " .sprintf "child died with signal %d, %s coredump",
         ($? & 127),  ($? & 128) ? 'with' : 'without';
    }elsif ($? != 0) {
	warn Dumper($ret);
        die localtime( time() ). " [ERROR] " .sprintf "child died with signal %d, %s coredump",
             ($? & 127),  ($? & 128) ? 'with' : 'without';
    }else {
        warn localtime( time() ). " [INFO] " . sprintf "child exited with value %d\n", $? >> 8;
    }
    return @{$ret};
}

