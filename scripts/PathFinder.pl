use warnings;
use strict;
use Data::Dumper;
my $use =<<"END";
use: perl $0 /path/to/rawdata samplesheet.csv
Fixup path finding tool as duct tape for my iontorrent workflow.
END

main();

sub main {
	
	my $rawData = shift @ARGV;
	die "Invalid path: '$rawData'.\n $use" if(not -e $rawData);
	my $mergedSamplesheet;
	while(scalar(@ARGV)){
		my $samplesheetfile = shift @ARGV;
		my $samplesheet = ReadSamplesheet($samplesheetfile);
		warn "READ".Dumper($samplesheet);
		$samplesheet=FindPath($samplesheet,$rawData);
		warn "FINDPATH".Dumper($samplesheet);
		push(@{$mergedSamplesheet},@{$samplesheet});
	}
	#ValidateControlSampleNames($mergedSamplesheet);
	print SamplesheetAsString($mergedSamplesheet);
}
sub FindPath {
	my $samplesheet = shift @_;
	my $startDir = shift @_;
	warn Dumper($samplesheet -> [0]);
	my $samplesheetNew;
	my $sampleCount = 0;
	for my $sample (@{$samplesheet}){
		$sampleCount++;
		warn localtime(time())."## INFO: running sample ".$sampleCount." of ".scalar(@{$samplesheet})."\n"; 
		#this goes wrong when no barcodes used so default t single array value with emplty string;
		my @barcodes;
		my @barcodesSeqs;
		if($sample -> {'barcodes'} eq ''){
			@barcodes=('');
			@barcodesSeqs=('');
		}else{
			@barcodes=split(';',$sample -> {'barcodes'});
                	@barcodesSeqs=split(';',$sample -> {'barcodeSequences'});
		}
		my $barcodeIndex = 0;
		while($barcodeIndex < scalar(@barcodes)){
			my $cmd = "find $startDir -iname ".$barcodes[$barcodeIndex]."*".$sample -> {'planExpName'}."*.bam";
			my $ret;
			@{$ret} = CmdRunner($cmd);
			
			warn "[INFO] system call results:\n";
			for (@{$ret}){
				chomp $_;
				print STDERR "`".$_."`\n";
			}

			if(defined($sample -> {'bamFiles'}) && length($sample -> {'bamFiles'}) > 3){ #remove if???
				$sample -> {'bamFiles'}.=";".join(";",@{$ret});
				#die "Clean this piece of code if not used";
			}else{
				$sample -> {'bamFiles'}=join(";",@{$ret});
				$sample -> {'reads1FqGz'}=join(";",@{$ret});
				$sample -> {'reads1FqGz'}=~ s/\.bam.*$/.fastq.gz/g;
				$sample -> {'reads2FqGz'}='';
				$sample -> {'reads3FqGz'}='';
				$sample -> {'internalId'}=$sample -> {'runNumber'}."_".$barcodes[$barcodeIndex];
				$sample -> {'project'}='projectNameHere';
				$sample -> {'controlSampleName'}=$sample -> {'sampleName'};
				$sample -> {'samplePrep'}=$sample -> {'planName'};
				$sample -> {'seqType'}=$sample -> {'sequencekitname'};
				$sample -> {'sequencer'}=$sample -> {'platform'};
				$sample -> {'sequencerId'}=$sample -> {'platform'};
				$sample -> {'run'}=$sample -> {'runNumber'};
				$sample	-> {'flowcellId'}=$sample -> {'chipBarcode'};
				$sample	-> {'lane'}=0;
				$sample	-> {'barcode'}=$barcodesSeqs[$barcodeIndex];
				$sample	-> {'sequencingStartDate'}=$sample -> {'runDate'};
				#samplePrep,seqType,sequencer,sequencerId,run,flowcellId,lane,barcode,sequencingStartDate
			}
			my $TMPsample=[$sample];
			#warn SamplesheetAsString($TMPsample) if(length($ret)> 10);
			#die $ret." ".Dumper($sample)." " if(length($ret)> 10);
			push(@{$samplesheetNew},$sample);
			$barcodeIndex++;
		}
		
		#die $ret." ".Dumper($sample)." " if(length($ret)> 10);

	}
	#die Dumper($samplesheetNew);
	return $samplesheetNew;
}
sub ReadSamplesheet {
	my $samplesheetf = shift @_;
	my $samplesheet;
	open( my $samplesheeth,'<', $samplesheetf) or die "Cannot read samplesheet file:'$samplesheetf'";
	$_=<$samplesheeth>;
	chomp;
	my @h = CommaseparatedSplit($_);
	#die Dumper(\@h);
	while(<$samplesheeth>){
		chomp;
		my @c = CommaseparatedSplit($_);
		#ValidateColvalues(\@h,\@c);
		ValidateSpecialChars(\@h,\@c);
		#die Dumper(\@c);
		my %d;
		my $i=0;
		map{$d{$_}=$c[$i]; $i++;}(@h);
		$i++;
		#$c[$i]=join(",",@h);
		#ReadFileNameConstructor(\%d);
		push(@$samplesheet,\%d);

	}
	return $samplesheet;
}
sub ValidateColvalues {
	my $header = shift @_;
	my $columns = shift @_;
	if(scalar(@{$header}) ne scalar(@{$columns})){
		die "[VALIDATIONERROR] number of columns (".scalar(@{$columns}).") in line $. are not equal to columns in header ".scalar(@{$columns})
			.".\nArray dump of header".Dumper($header)
			.".\nArray dump of $. columns".Dumper($columns)." ";
	}
}
sub ValidateSpecialChars {
        my $header = shift @_;
        my $columns = shift @_;
	for my $field (@{$header}, @{$columns}){
		if($field =~ /[\&\%\@\$\'\"\[\]\{\}\*\!\~\`]/){
			die "[VALIDATIONERROR] field '".$field."' matches /[ \#\&\%\@\$\-\'\"\[\]\{\}\*\!\~\`]/ in line '$.' "
                	        .".\nArray dump of header".Dumper($header)
                	        .".\nArray dump of $. columns".Dumper($columns)." ";
		}
                if($field =~ /[ \-]/){
                        warn "[VALIDATIONERROR] field '".$field."' matches /[\-]/ in line '$.'. Consider removing.";
                }

	}
}

sub ValidateControlSampleNames {
	my $samplesheet = shift @_;
	
	#my $samplesh	
	return if (not(defined($samplesheet -> [0] -> {'controlSampleName'})));
	my @s;#sample
	map{push(@s, $_ -> {'project'}."|".$_ -> {'sampleName'})}(@{$samplesheet});
	my $i=1;
	my $cs;	#controlsample
	map{push(@{$cs}, {'project' => $_ -> {'project'}, 'controlSampleName' => $_ -> {'controlSampleName'}, 'line' =>  $i}); $i++;}(@{$samplesheet});
	my $error = "";
	map{
		my $csname = $_ -> {'controlSampleName'};
		my $csproject = $_ -> {'project'};
		my $csline = $_ -> {'line'};
		my $seen = 0;
		map{
			$seen++ if($_ eq $csproject.'|'.$csname);
		}(@s);
		$error = "'".$csname."' in project '".$csproject."' at $csline," if(not($seen));
	}(@{$cs});
	chop $error;
	die "[VALIDATIONERROR] The following samplename(s) are seen in the controlsamplenames row but not seen in the samplenames row for the project (format'controlsaplename' at \$lineno) : \n".$error if($error ne "");
}
sub CommaseparatedSplit {
	my $string=pop @_;
	#needs to be fixed for citation marks!
	warn "Line contains citation marks: this is currently not supported!!. I hope this works. Line=$_" if($string =~ /"|'/);
	my $i = index($string,",");
	if( $i > -1){
		push(@_,substr($string,0,$i));
		push(@_,substr($string,$i+1));
		@_ = CommaseparatedSplit( @_ );
	}else{
		push(@_,$string);
		return @_;
	}
}

sub SamplesheetAsString {
	my $self = shift @_;
	my $string = '';
	#get header values;
	my %h;
	for my $sample (@$self){
		for my $key (keys(%$sample)){
			$h{$key}++;
		}
	}
	my @h = sort {$b cmp $a} (keys(%h));
	$string.=join(",",@h)."\n";
	#warn scalar(@$self);
	for my $sample (@$self){
		my @c;
		for my $h (@h){
			push (@c,$$sample{$h});
		}
		$string.=join(",",@c)."\n";
	}
	return $string;
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
