#!/usr/bin/perl
use strict;
use warnings;
my $use = <<"END";
	converts parameters files
	param,value
	param2,value2
	to
	param,param2
	value,value2
	for molgenis
	
	supports the removal of comments (lines starting with #) and empty lines for notes
	
	does not support citation marks to include comma's
	
	use: $0 parameters.csv > parameters.molgenis.csv
END
die $use if(scalar(@ARGV)==0);
die "$ARGV[0] does not exist. Is it a file? \n".$use if(not( -e $ARGV[0]));
my @param; my @val; my %h; my $lc;
while(<>){
	next if(/^\s*$|^#/);#
	warn "## ".localtime(time)." ## WARN ## char '=' found try char ','" if(/=/);
	chomp;
	my $param; my $val;
	($param, $val)=split(",");
	push(@param, $param);
	push(@val,$val);
	die "Duplicate parameter '$param' detected!\nPlease remove and restart.\nold value is '$h{$param}' and new value is '$val'" if(defined($h{$param}));
	$h{$param}=${val};
	$lc += 1;
}
warn "## ".localtime(time)." ## INFO ## Used $lc lines of $. \n";
print join(",",@param)."\n";
print join(",",@val)."\n";
