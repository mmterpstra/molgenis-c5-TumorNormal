use warnings;
use strict;
use Data::Dumper;
my $use =<<"END";
use: perl $0 samplesheet.csv
Validator tool.
Exits with error if there are errors in the samplesheet.
END

main();

sub main {
	my $mergedSamplesheet;
	while(scalar(@ARGV)){
		my $samplesheetfile = shift @ARGV;
		my $samplesheet = ReadSamplesheet($samplesheetfile);
		push(@$mergedSamplesheet,@$samplesheet);
	}
	ValidateControlSampleNames($mergedSamplesheet);
	ValidateFqFiles($mergedSamplesheet);
	ValidateInternalId($mergedSamplesheet);
	print SamplesheetAsString($mergedSamplesheet);
}

sub ReadSamplesheet {
	my $samplesheetf = shift @_;
	my $samplesheet;
	warn "[INFO] Analysing file '$samplesheetf'.\n";
	open( my $samplesheeth,'<', $samplesheetf) or die "[ERROR] Cannot read samplesheet file:'$samplesheetf'";
	$_=<$samplesheeth>;
	chomp;
	my @h = CommaseparatedSplit($_);
	#die Dumper(\@h);
	while(<$samplesheeth>){
		chomp;
		my @c = CommaseparatedSplit($_);
		ValidateColvalues(\@h,\@c);
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
	ValidateHeader($header);
	my $columns = shift @_;
	if(scalar(@{$header}) ne scalar(@{$columns})){
		die "[VALIDATIONERROR] number of columns (".scalar(@{$columns}).") in line $. are not equal to columns in header ".scalar(@{$columns})
			.".\nArray dump of header".Dumper($header)
			.".\nArray dump of columns on line $. : ".Dumper($columns)." ";
	}
}
sub ValidateSpecialChars {
        my $header = shift @_;
        my $columns = shift @_;
	for my $field (@{$header}, @{$columns}){
		if($field =~ /[ \&\%\@\$\'\"\[\]\{\}\*\!\~\`]/){
			die "[VALIDATIONERROR] field '".$field."' matches /[ \#\&\%\@\$\-\'\"\[\]\{\}\*\!\~\`]/ in line '$.' "
                	        .".\nArray dump of header".Dumper($header)
                	        .".\nArray dump of $. columns".Dumper($columns)." ";
		}
                if($field =~ /[\-]/){
                        warn "[VALIDATIONWARNING] field '".$field."' matches /[\-]/ in line '$.'. Consider removing.";
                }

	}
}
sub ValidateHeader {
	my $header = shift(@_);
	
	my @requiredValues = (
		'internalId',
		'samplePrep',
		'seqType',
		'sequencer',
		'sequencerId',
		'run',
		'flowcellId',
		'lane',
		'sampleName',
		'barcode',
		'sequencingStartDate',
		'project',
		'controlSampleName',
		'reads1FqGz',
		'reads3FqGz',
		'reads2FqGz');
	
	my @dieRequired = ();
	for my $requirement (@requiredValues){
		push(@dieRequired,$requirement) if(scalar(grep(${requirement} eq $_,@{$header})) != 1);
		warn "[VALIDATIONWARNING] is this ok? $requirement ".join(',',(@{$header}, scalar(grep(${requirement} eq $_,@{$header})) )) if(scalar(grep(${requirement} eq $_ , @{$header})) != 1);
	}
	die "[VALIDATIONERROR] Missing required field(s) or field(s) declared twice: '".join(',',@dieRequired)."' in samplesheet header '".join(',',@{$header})."'" if(scalar(@dieRequired)>0);
	
	
	#(
	#	'reads1FqGz',
	#	'reads3FqGz',
	#	'reads2FqGz'
	#);
	
	#@{$header}
	#die Dumper($header);
}

sub ValidateControlSampleNames {
	my $samplesheet = shift @_;
	
	#my $samplesh	
	return if (not(defined($samplesheet -> [0] -> {'controlSampleName'})));
	my %combihash;
	my $s;#sample
	#gather array for checking the controlsample per project and one for checking amount of combinations
	map{push(@{$s}, $_ -> {'project'}."|".$_ -> {'sampleName'});
		$combihash{ $_ -> {'project'} }{'samples'}{ $_ -> {'sampleName'} }++;
		$combihash{ $_ -> {'project'} }{'controlsampleNames'}{ $_ -> {'controlSampleName'} }++;
		$combihash{ $_ -> {'project'} }{'samplecontrol'}{ $_ -> {'sampleName'} . '|' . $_ -> {'controlSampleName'} }++;
	}(@{$samplesheet});
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
		}(@{$s});
		$error = "'".$csname."' in project '".$csproject."' at $csline," if(not($seen));
	}(@{$cs});
	
	#reduce the amount of normals
	my $maxcontrol = 3;
	for my $project (keys %combihash){
		warn "[VALIDATIONWARNING] project '".$project.
			"' has amount of samples '".scalar(keys(%{$combihash{$project}{'samples'}})).
			"' has amount of controls '".scalar(keys(%{$combihash{$project}{'controlsampleNames'}})).
			"' amount of controlsamples/sample combinations '".scalar(keys(%{$combihash{$project}{'samplecontrol'}}))."'\n";
		die "[VALIDATIONERROR] in project '$project' amount of controlsamples '".scalar(keys(%{$combihash{$project}{'controlsampleName'}}))."' exceeds '$maxcontrol'" if( scalar(keys(%{$combihash{$project}{'controlsampleName'}})) > $maxcontrol); 
	}
	
	chop $error;
	die "[VALIDATIONERROR] The following samplename(s) are seen in the controlsamplenames row but not seen in the samplenames row for the project (format'controlsaplename' at \$lineno) : \n".$error if($error ne "");
	
	
}
sub ValidateFqFiles {
	my $samplesheet = shift @_;
	for my $fileparam ('reads1FqGz',
        	'reads3FqGz',
        	'reads2FqGz'){
		#next if (not(defined($samplesheet -> [0] -> {$file})));
		for my $sample (@{$samplesheet}){
			next if(not(defined($sample -> {$fileparam})));
			die "[VALIDATIONERROR] Invalid file '".$sample -> {$fileparam}."' in parameter '".$fileparam."' ".Dumper($sample) 
				if(defined($sample -> {$fileparam}) &&  $sample -> {$fileparam} ne "" && ! -e $sample -> {$fileparam});
		}
	}
}
sub ValidateInternalId {
	my $samplesheet = shift @_;
	for my $param ('internalId'){
		my %seen;
		#next if (not(defined($samplesheet -> [0] -> {$file})));
		for my $sample (@{$samplesheet}){
			next if(not(defined($sample -> {$param})));
			die "[VALIDATIONERROR] Invalid sampleid/file mapping seen internalId id'".
				$sample -> {$param}.
				"' sample'".$sample -> {'sampleName'}."' more than once with different files: '".
				$sample -> {'reads1FqGz'}.
				"' & '".$seen{ $sample -> {$param} }{ $sample -> {'sampleName'} }{'fileold'}.
				"'" 
				if(defined($seen{ $sample -> {$param} }{ $sample -> {'sampleName'} }{'seen'}) && 
				defined($seen{ $sample -> {$param} }{ $sample -> {'sampleName'} }{'fileold'}) &&
				$seen{ $sample -> {$param} }{ $sample -> {'sampleName'} }{'fileold'} ne $sample -> {'reads1FqGz'});
			$seen{ $sample -> {$param} }{ $sample -> {'sampleName'} }{'seen'}++;
			$seen{ $sample -> {$param} }{ $sample -> {'sampleName'} }{'fileold'}=$sample -> {'reads1FqGz'};
		}
		warn Dumper(\%seen);
	}
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
			if(defined($$sample{$h})){
				push (@c,$$sample{$h});
			}else{
				push (@c,'');
			}
		}
		$string.=join(",",@c)."\n";
	}
	return $string;
}
