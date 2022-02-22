#!/usr/bin/env perl
use warnings;
use strict;
use Vcf;
use Data::Dumper;

my $use = <<"END";
	$0 in.vcf out.vcf
	soft filter opencravat data.
END

die "no valid 'in.vcf' specified on command line\n$use" if(not(defined($ARGV[0])) ||not -e $ARGV[0]);
#main
main($ARGV[0],$ARGV[1]);

sub main{
	my $vcfin = $_[0];#'/home/terpstramm/Downloads/s12-193.annotated.vcf';
	my $out;
	if($_[1] && not(-e $_[1])){
		my $vcfout = $_[1];
		open($out,'>',$vcfout) or die 'Cannot write vcf file';
	}else{
		warn localtime(time())." [WARN] $0: no output vcf file specified printing to STDOUT"."\n";
		$out =*STDOUT;
	}
	#yolo manual
	#f=gnomad af filter criteria
	#s=comma separated strings to filter base__so from opencravat
	#
	my $opts = {'f' => 0.01,									#frequency GNomad
		's' => ',"synonymous","intron","3-prime-utr","5-prime-utr","2kb-upstream",', 	#annotation
		'c' => 15,										#CADD score
		'd' => 10};										#mindepth sumAD
	
	warn localtime(time())." [INFO] $0: Parsing header.";
	my $vcf = Vcf->new(file=>$vcfin);
	#warn "parse header";
	$vcf->parse_header();
	#warn "get annotations";
	my $annotations;
	#warn "####".Dumper($vcf->get_header_line(key=>'INFO', ID=>'ANN')) ."####";
	my $crvheaderline = $vcf->get_header_line(key=>'INFO', ID=>'CRV');
	if(defined($crvheaderline) && scalar(@{$crvheaderline})){
		$annotations = GetCrvFunctionalAnnotations($crvheaderline);
		#warn "set annotations";
		#SetFiltersCRV('vcf' => $vcf, 'ann' => $annotations);
		my $base__so_filter_clean = $opts -> {'s'};
		$base__so_filter_clean =~ s/['"]//g;
		my $headerlines;@{$headerlines} = ({key=>'FILTER', ID=>'AFFilter', Description=>'Filter based on AF in gnomad < '.$opts -> {'f'}.'.'},
			{key=>'FILTER', ID=>'SumAdlt10Filter', Description=>'Sum of allele depth less than '.$opts -> {'d'}.' .'},
			{key=>'FILTER', ID=>'SoFilter', Description=>'SoFilter filter opencravat non-functional filter for BASE__SO field ('.$base__so_filter_clean.').'},
			{key=>'FILTER', ID=>'CaddPred10Filter', Description=>'CADD filter opencravat non-functional filter for cadd phred > '.$opts -> {'c'}.' .'},
			{key=>'FILTER', ID=>'PASS', Description=>'All filters passed'});
		for my $headerline (@{$headerlines}){
			$vcf -> add_header_line($headerline);
		}
	}else{
		warn localtime(time())." [WARN] $0: Possible broken/empty input no ANN info field found!";
	}
	print {$out} $vcf->format_header();
	#die "header check";
	#$vcf->recalc_ac_an(0);
	warn localtime(time())." [INFO] $0: Iterating records."; my $records=0;
	my %stats;
	while (my $x=$vcf->next_data_array()){
		if(defined($crvheaderline) && scalar(@{$crvheaderline})){
			#FillSNPEFFANNFields('record' => $x,'ann' => $annotations);
			
			#setting things up for filtering
			my $crvparsed = ParseCrvAnnotations('ann' => $annotations, 'crv'=> GetCrv('x' => $x));
			$stats{'BASE__SO'}{$crvparsed -> {'BASE__SO'} }++;
			
			#die Dumper($x, $crvheaderline, $annotations,$crvparsed);
			if(not(defined($x -> [6])) or $x -> [6] eq "." ){
				$x -> [6] = "PASS";
			}
			my $filters;@{$filters} = ();
			
			#af gnomad filtereing
			if(defined($crvparsed -> {'GNOMAD3__AF'}) && not($crvparsed -> {'GNOMAD3__AF'} eq '')){
				my @GnomadAF = split(',',$crvparsed -> {'GNOMAD3__AF'});
				my $GnomadFiltered=0;
				for my $af (@GnomadAF){
					if(defined($af) && not($af eq '')){
						if($af > $opts -> {'f'}){
							$GnomadFiltered=1;
							push(@{$filters},'AFFilter');
							$stats{'filter'}{'AFFilter'}++;
						}
					}
				}
			}
			#sumAD filter
			#warn "## sum=".GetSumAD('x' => $x)." ";
			if(GetSumAD('x' => $x) < $opts -> {'d'}){
					push(@{$filters},'SumAdlt10Filter');
					$stats{'filter'}{'SumAdlt10Filter'}++;
			}
				
			#############effect filtering
			my $base__soFiltered = 0;
			my @filters = split(',',$opts -> {'s'});
			
			for my $filter (@filters){
				if($crvparsed -> {'BASE__SO'} eq $filter){
					$base__soFiltered = 1;
				}
			}
			if($base__soFiltered > 0){
				push(@{$filters},'SoFilter');
				$stats{'filter'}{'SoFilter'}++;
			}
			
			##caddd filtering 10?
			my @caddexomephred = split(',',$crvparsed -> {'CADD_EXOME__PHRED'});
			for my $cadd (@caddexomephred){
				if(defined($cadd) && not($cadd eq '')){
					if($cadd < $opts -> {'c'}){
						push(@{$filters},'CaddPred10Filter');
						$stats{'filter'}{'CaddPred10Filter'}++;
					}
				}
			}
			if((not(defined($x -> [6])) or $x -> [6] eq "." or $x -> [6] eq "PASS") && scalar(@{$filters}) > 0){
				$x -> [6] = join(';',@{$filters});#replace filter
			}elsif(scalar(@{$filters}) > 0){
				$x -> [6] .= ';'.join(';',@{$filters});
			}
		}
		print {$out} $vcf->format_line($x);
		$records++;
#               if(scalar(@{GetAlt($x)})>1){
#				die Dumper($x)."\n".GetAlt($x)."\n".$. ;
#		}

	}
	$vcf->close();
	warn localtime(time())." [INFO] $0: Done. Processed $records";
	warn "Ugly dump of filtering results".Dumper(\%stats)."";
}
sub GetCrv {
	#get teh crv field values from the array format vcf info field
	my $self;
	%{$self}= @_;
	my $record = $self -> {'x'};
	my $crv;
	if(index($record -> [7],'CRV=') > -1){
		my $fieldstart = index($record -> [7],'CRV=') + 4;
		if(index($record -> [7],';',$fieldstart) > -1){
			$crv = substr($record -> [7],$fieldstart,index($record -> [7],';',$fieldstart));	
		}else{
			$crv = substr($record -> [7],$fieldstart);
		}
	}
}
sub GetSumAD {
	my $self;
	%{$self}= @_;
	my $record = $self -> {'x'};
	
	die "Genotype count > 1 this aint ment for filtering multiple samples in a single vcf amount of (vcf) columns " if scalar(@{$record}) > 10;
	my $format = $record -> [8]; my $gtinfo = $record -> [9];
	my $gt;
	@{$gt} = split(':',$gtinfo);
	my $gtparsed;
	map{$gtparsed -> {$_} = shift(@{$gt});}(split(":",$format));
	#warn Dumper($gtparsed);
	my $sum = 0;
	map{$sum += $_;}(split(',',$gtparsed -> {"AD"}));
	return $sum;
}
sub GetCrvFunctionalAnnotations {
	my $crvParsed = shift @_ or die "no input given for subroutine";
	die "invalid input".Dumper($crvParsed) if(not(defined($crvParsed -> [0] -> {'Description'})));
	my $crvdescr = $crvParsed -> [0] -> {'Description'};
	$crvdescr =~ s/Functional\ annotations\:\ \'|\'//g;
	my $crvdescrvcf = $crvdescr;
	$crvdescrvcf =~ s/ \/ /_AND_/g;
	$crvdescrvcf =~ s/\./_/g;
	
	my $annotations;
	#@{$annotations}
	
	my @anns = split('\|', $crvdescr);
	my @crvsVcf = split('\|', $crvdescrvcf);
	for my $crvVcf (@crvsVcf){
		my $ann = shift(@anns);
		my ($name) = split('=',$crvVcf); 
		my %h = ('name' => uc($name),'alias' => $ann);
		#this is BS reporting fields in the header but never outputting them!#!4!#%%#$^$%&*
		if(substr($name,0,9) ne 'vcfinfo__'){
					push(@{$annotations},\%h);
		}
	}

    return $annotations;
}
sub ParseCrvAnnotations {
	my $self;
	%{$self}= @_;
	my $ann = $self -> {'ann'} or die "no vcf object as input";
	my $crv = $self -> {'crv'} or die "no vcf object as input";
	my @crvvals = split('\|', $crv);
	#warn $crv, Dumper(@crvvals);
	my $parsed;
	my $index=0;
	map{$parsed -> {$ann -> [$index] -> {'name'}} = $_; $index++}(@crvvals);
	return $parsed;
}
sub SetHeadersSNPEFFANN {
	my $self;
	%{$self}= @_;
	my $vcf = $self -> {'vcf'} or die "no vcf object as input";
	my $annotations = $self -> {'ann'} or die "no ann object(annotations) as input";
	for my $annotation (@{$annotations}){
		
		$vcf -> add_header_line({'key' => 'INFO', 'ID' => SnpEffAnnField($annotation -> {'name'}), 'Number' => 'A','Type' => 'String','Description' => 'Snpeff field: ' . SnpEffAnnField($annotation -> {'alias'}) . '. This is an subfield of the SnpEff annotation selected by ' . $0 . ' on the most harmful prediction. The format is described on http://snpeff.sourceforge.net/SnpEff_manual.html .'});
		
	}
	
}
sub SnpEffAnnField{
	return 'SNPEFFANN_'.shift @_;
}
sub GetAnn{
	my $r = shift @_;
	if(defined($r->{'INFO'}{'ANN'})){
		return $r->{'INFO'}{'ANN'};
	}
	#iffy merges need lots of warnings snpeff even shies away from spanning deletions
	warn "Vcf record doesn't have ANN INFO Field or is strangely annotated!" . Dumper($r) . ' ';
	return undef;
}
sub GetAlt{
	my $r = shift @_;
	if(defined($r->{'ALT'})){
		return $r->{'ALT'};
	}
	die "Vcf record doesn't have ALT Field or is strangely annotated!".Dumper($r);
}
sub FillSNPEFFANNFields {
	my $self;
	%{$self}= @_;
	my $r = $self -> {'record'} or die "no record object as input";
	my $annotations = $self -> {'ann'} or die "no ann object(annotations) as input";
	AnnotateRecordAnnFields('record' => $r,'ann' => $annotations);
}
sub AnnotateRecordAnnFields {
	my $self;
	%{$self}= @_;
	my $r = $self -> {'record'} or die "no record object as input";
	my $annotations = $self -> {'ann'} or die "no ann object(annotations) as input";
	my $worstPredsByAllele = GetWorstPredictionsByAllele('record' => $r,'ann' => $annotations);
	my $worstPredsByAlleleParsed = ParseAnnotation('annfields'=>$worstPredsByAllele,'ann'=>$annotations);
	
	for my $field (@{$worstPredsByAlleleParsed}){
		$r -> {'INFO'} -> {SnpEffAnnField($field -> {'name'})}=join(',',@{$field -> {'values'}});
	}
	#print Dumper($worstPredsByAlleleParsed,$r);
	#die Dumper($worstPredsByAlleleParsed,$r);
}
sub GetWorstPredictionsByAllele {
	my $self;
	%{$self}= @_;
	my $r = $self -> {'record'} or die "no record object as input";
	my $annotations = $self -> {'ann'} or die "no ann object(annotations) as input";
	
	#$worstPredsByAlt -> {alleles} = [ALT]
	#$worstPredsByAlt -> {ANNFIELDS} -> [FORALT results];
	my $alts = GetAlt($r);
	my @worstAnnotations;
	for my $alt (@{$alts}){
		my $worstAnnotation = GetWorstAnnByAllele('record'=>$r,'alt'=>$alt,'ann'=>$annotations);
		push(@worstAnnotations,$worstAnnotation );
		die "Missing annotation field in record?!" if(not(defined($worstAnnotation)));
	}
	
	return \@worstAnnotations;
}

sub GetWorstAnnByAllele {
	my $self;
	%{$self}= @_;
	
	#tries to get the first annotation per alle and assumes this is the 
	# worst effect.  
	
	my $r = $self -> {'record'} or die "no record object as input";
	my $alt = $self -> {'alt'} or die "no alt value as input";
	my $annotations = $self -> {'ann'} or die "no annotations object value as input";
	
	my @anns;
	@anns = split(",",GetAnn($r)) if(defined(GetAnn($r)));
	my $spanningDeletionAnn = '*'.'|.'  x (scalar(@{$annotations}) - 1);
	push(@anns,$spanningDeletionAnn);

	
	my $worstAnn;
	
	while(not(defined($worstAnn))){
		my $ann = shift @anns;
		$worstAnn = $ann if (GetAnnotationAllele('annfields' => [$ann],'ann' => $annotations) eq $alt);
	}
	return $worstAnn;
	
}

sub ParseAnnotation {
	my $self;
	%{$self}= @_;
	my $annFields = $self -> {'annfields'} or die "no annotations object value as input";
	my $annotationHeader = $self -> {'ann'} or die "no annotations object value as input";

	my $parsed;

	for my $annField (@{$annFields}){
		my @anns = split /\|/,$annField,-1;
		die "Annotations not equal to header:\n".Dumper(\$annField,\@anns,$annotationHeader) if(not(scalar(@anns)==scalar(@{$annotationHeader})));
		
		my $fieldindex = 0;
		#die Dumper($annotationHeader);
		while($fieldindex < scalar(@{$annotationHeader})){
			$parsed -> [$fieldindex] -> {'name'} = $annotationHeader -> [$fieldindex] -> {'name'};
			push(@{$parsed -> [$fieldindex] -> {'values'}},$anns[$fieldindex]);
			$fieldindex++;
		}
	}
	return $parsed;
}
sub GetAnnotationAllele {
	my $self;
	%{$self}= @_;
	my $annField = @{$self -> {'annfields'}}[0] or die "no annotations object value as input";
	my $annotationHeader = $self -> {'ann'} or die "no annotations object value as input";
	my $parsed = ParseAnnotation(%{$self});
	for my $annotation (@{$parsed}){
		return $annotation -> {'values'} -> [0] if($annotation -> {'name'} eq 'ALLELE' && scalar(@{$annotation -> {'values'}}) == 1);
	}
}
