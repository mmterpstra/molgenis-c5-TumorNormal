#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
#Needs samtools binary/picard jarfiles hardcoded in script
my $use = <<"END1";
Use $0 PICARDJAR FILE(s)
	Tries to remove samplenames from bam/sam samplenames are extracted from SM field in header
	PICARDJAR Needs picard jarfile path in script
	FILE Needs *.bam
END1

if (scalar(@ARGV)==0){
	print $use;
	exit(0);
}

my $sampleCount = 0;
my %sampleNameToSampleCount;
my $picardjar = shift(@ARGV);
for my $bamfile (@ARGV){
	next if(not -e $bamfile);
	my $header=ExtractSamHeader(\$bamfile);
	warn "got header";
	my @sampleNames = GetSampleNames(\$header);
	warn "got samplename";
	my $bamOutputName = 'Sample_'.$sampleCount;
	if(scalar(@sampleNames) > 1){
		my $upperindex =($sampleCount + scalar(@sampleNames) - 1);
		$bamOutputName = $bamOutputName.'_to_'.$upperindex;
	}
	$bamOutputName = $bamOutputName.'.bam';
	for my $sampleName (@sampleNames){
		my $newSampleName = 'sample'.$sampleCount;
		$sampleNameToSampleCount{$bamfile}{$sampleName}{$newSampleName} = $bamOutputName;
		ReplaceSampleName(\$sampleName,\$newSampleName,\$header);
		$sampleCount++;
	}
	ReplaceSamHeaderAndRenameFile(\$bamfile, \$bamOutputName, \$header, $picardjar);
}
warn Dumper(\%sampleNameToSampleCount);
exit(0);

sub ExtractSamHeader{
	my $samtoolsViewCmd = "samtools view -H ".${$_[0]};
	warn $samtoolsViewCmd."\n";
	my $header = join("",CmdRunner($samtoolsViewCmd)); #no newline here or picard creates a strange soup...
	return $header;
}
sub GetSampleNames{
	my @lines = split("\n",${$_[0]});
	#warn @lines." ";
	my %sampleNames;
	for my $line (@lines){
		if($line =~ /^\@RG.*SM:(\S*)/){
			$line =~ /^\@RG.*SM:(\S*)/;
			my $sampleName = $1;
			$sampleNames{$sampleName}++;
		}
	}
	warn '## samplenames '.join(':',keys(%sampleNames))."##\n";
	return keys(%sampleNames);
}
sub SamtoolsIndexBam {
	my $samtoolsIndexCmd = "samtools index ".${$_[0]};
	warn CmdRunner($samtoolsIndexCmd);
}	

sub ReplaceSampleName{
	#(\$header)
	#input like (\$sampleName,\$newSampleName,\$header);
	${$_[2]}=~ s/${$_[0]}/${$_[1]}/ge;
	#fq files are tricky so
	${$_[2]}=~ s/\S*(_\d.\|\.)(fq|fastq)\.gz/\/path\/to\/some$1.fastq.gz/g;
	#warn $$_[2];
}
sub ReplaceSamHeaderAndRenameFile{
	open my $out, '>'. ${$_[1]}.'.samheader.sam';
	print $out "${$_[2]}";
	my $PicardCmd = "java -jar $_[3] ReplaceSamHeader HEADER=".${$_[1]}.".samheader.sam I=".${$_[0]}." O=".${$_[1]};
	warn $PicardCmd."\n";
	warn CmdRunner($PicardCmd); 
}
sub CmdRunner {
    my $ret;
    my $cmd = join(" ",@_);

    warn localtime( time() ). " [INFO] system call:'". $cmd."'.\n";

    @{$ret} = `($cmd )2>&1`;
    if ($? == -1) {
        die localtime( time() ). " [ERROR] failed to execute: $!\n";
    }elsif ($? & 127) {
        die localtime( time() ). " [ERROR] " .sprintf "child died with signal %d, %s coredump",
         ($? & 127),  ($? & 128) ? 'with' : 'without';
    }elsif ($? != 0) {
        die localtime( time() ). " [ERROR] " .sprintf "child died with signal %d, %s coredump",
             ($? & 127),  ($? & 128) ? 'with' : 'without';
    }else {
        warn localtime( time() ). " [INFO] " . sprintf "child exited with value %d\n", $? >> 8;
    }
    return @{$ret};
}
