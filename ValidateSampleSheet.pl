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
	print SamplesheetAsString($mergedSamplesheet);
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
		if($field =~ /[ \&\%\@\$\'\"\[\]\{\}\*\!\~\`]/){
			die "[VALIDATIONERROR] field '".$field."' matches /[ \#\&\%\@\$\-\'\"\[\]\{\}\*\!\~\`]/ in line '$.' "
                	        .".\nArray dump of header".Dumper($header)
                	        .".\nArray dump of $. columns".Dumper($columns)." ";
		}
                if($field =~ /[\-]/){
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
