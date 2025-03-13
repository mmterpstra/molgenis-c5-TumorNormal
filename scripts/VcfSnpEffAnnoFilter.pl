#!/usr/bin/env perl
use warnings;
use strict;
use Vcf;
use Data::Dumper;
#use Devel::StackTrace;
use Getopt::Std;
my $use = <<"END";
	$0 in.vcf out.vcf
	soft filter opencravat data.
END
my %opts;
getopts('h:s:c:d:a:n:m:f:r:n:p:', \%opts);
die "no valid 'in.vcf' specified on command line\n$use" if(not(defined($ARGV[0])) ||not -e $ARGV[0]);
#main

main(\%opts,$ARGV[-1]);

sub main{
	my $vcfin = $_[1];#'something.vcf';
	my $out;
	if($_[2] && not(-e $_[2])){
		my $vcfout = $_[2];
		open($out,'>',$vcfout) or die 'Cannot write vcf file';
	}else{
		warn localtime(time())." [WARN] $0: no output vcf file specified printing to STDOUT"."\n";
		$out =*STDOUT;
	}
	#yolo manual
	#f=gnomad af filter criteria
	#s=comma separated strings to filter base__so from opencravat
	#splice_acceptor_variant
	#splice_donor_variant
	my $opts;$opts = {'f' => 0.001,						#frequency GNomad
		's' => 'TF_binding_site_variant,splice_region_variant,3_prime_UTR_variant,coding_sequence_variant,synonymous_variant,structural_interaction_variant,downstream_gene_variant,upstream_gene_variant,exon_variant,gene_variant,duplication,intergenic_region,conserved_intergenic_variant,intragenic_variant,intron_variant,conserved_intron_variant,initiator_codon_variant,stop_retained_variant,5_prime_UTR_variant,5_prime_UTR_premature_start_codon_gain_variant,start_retained,stop_retained_variant,3_prime_UTR_truncation + exon_loss,5_prime_UTR_truncation + exon_loss_variant,sequence_feature + exon_loss_variant,sequence_feature,non_coding_transcript_exon_variant', 	
		# --filterExpression "!((vc.hasAttribute('SNPEFFANN_ANNOTATION_IMPACT') && 
		#vc.getAttribute('SNPEFFANN_ANNOTATION_IMPACT').contains('HIGH'))
		#||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('missense_variant'))
		#||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('coding_sequence_variant'))
		#||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('inframe_insertion'))
		#||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('disruptive_inframe_insertion'))
		#||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('inframe_deletion'))
		#||(vc.hasAttribute('SNPEFFANN_ANNOTATION') && vc.getAttribute('SNPEFFANN_ANNOTATION').contains('disruptive_inframe_deletion')))" \
		#^ annotation
		'c' => 15,								#CADD score
		'd' => 10,								#mindepth sumAD
		'v' => 0.01,							#min vaf
		'a' => 4,								#mindepth alt reads
		'n' => '',								#name
		'f' => 0.001,							#rare var frequency cutoff
		's' => 60,								#HcCallerFisherStrand
		'm' => -12.5,							#HcCallerMQranksum
		'h' => '0.75',							#het cutoff
		'r' => '/groups/umcg-pmb/tmp01/apps/data/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta',	#reference seq
		'p' => 5, 								#N or more repeats not allowed
	};										
	#hidden 'a' => "some.csv" ;#this contains af / ad data in csv format:dp,ad[0],ad[1],f";
	my $cmdopts = $_[0];
	for my $key (keys(%{$_[0]})){
		$opts -> {$key}=$cmdopts -> {$key};
	};
	warn localtime(time())." [INFO] $0: Parsing header.";
	my $vcf = Vcf->new(file=>$vcfin);
	my $csv;open($csv,'>',$opts -> {'a'}) or die "Can't open > ".$opts -> {'a'}.": $!" if(defined($opts -> {'a'}));
	print {$csv} "filter,dp,ad1,ad2,f\n" if(defined($opts -> {'a'}));
	#warn "parse header";
	$vcf->parse_header();
	#warn "get annotations";
	my $annotations;
	#warn "####".Dumper($vcf->get_header_line(key=>'INFO', ID=>'ANN')) ."####";
	#my $crvheaderline = $vcf->get_header_line(key=>'INFO', ID=>'CRV');
	my $annheaderline = $vcf->get_header_line(key=>'INFO', ID=>'ANN');
	if(defined($annheaderline) && scalar(@{$annheaderline})){
		$annotations = GetAnnFunctionalAnnotations($annheaderline);
		#warn "set annotations";
		SetHeadersSNPEFFANN('vcf' => $vcf, 'ann' => $annotations);
	}else{
		warn localtime(time())." [WARN] $0: Possible broken/empty input no ANN info field found!";
	}
		#SetFiltersCRV('vcf' => $vcf, 'ann' => $annotations);
		my $annfilter = $opts -> {'s'};
		$annfilter =~ s/['"]//g;
	my $headerlines;@{$headerlines} = (
		{key=>'FILTER', ID=>'NoSampleInfo', Description=>'Filter based on availability of sample data of sample '.$opts -> {'n'}.'.'},
		{key=>'FILTER', ID=>'AFlt'.$opts -> {'f'}.'Filter', Description=>'Filter based on (allele frequency) AF in gnomad < '.$opts -> {'f'}.'.'},
		{key=>'FILTER', ID=>'SumAdlt'.$opts -> {'d'}.'Filter', Description=>'Sum of allele depth less than '.$opts -> {'d'}.' .'},
		{key=>'FILTER', ID=>'AdAltGt'.$opts -> {'a'}.'Filter', Description=>'Allele depth of alt greater then '.$opts -> {'a'}.' .'},
		{key=>'FILTER', ID=>'VAFgt'.$opts -> {'v'}.'Filter', Description=>'Variant allele frequenc of alt greater then '.$opts -> {'v'}.' .'},
		{key=>'FILTER', ID=>'HetGt'.$opts -> {'h'}.'Filter', Description=>'Alt fraction greater then '.$opts -> {'h'}.' .'},
		{key=>'FILTER', ID=>'EffFilter', Description=>'Filter for non functional variants ('.$annfilter.').'},
		{key=>'FILTER', ID=>'Caddgt'.$opts -> {'c'}, Description=>'CADD filter for cadd phred > '.$opts -> {'c'}.' .'},
		{key=>'FILTER', ID=>'HcFisherStrand'.$opts -> {'s'}, Description=>'Fisherstrand filter for haplotypecaller HCallerFS > '.$opts -> {'s'}.' .'},
		{key=>'FILTER', ID=>'HcMQRankSum'.$opts -> {'m'}, Description=>'MappingQualityRankSum filter for haplotypecaller HCallerMQRankSum > '.$opts -> {'m'}.' .'},
		{key=>'FILTER', ID=>'HcMQRankSum'.$opts -> {'m'}, Description=>'MappingQualityRankSum filter for haplotypecaller HCallerMQRankSum > '.$opts -> {'m'}.' .'},
		{key=> 'INFO', ID=>'RepeatCount',Number=>"R",Type=>'Integer', Description=>'Count of repeated alts. 1 = no repeat'},
		{key=> 'INFO', ID=>'RepeatCountRepeatUnit',Number=>"R",Type=>'String', Description=>'Repeated unit'},
		{key=>'FILTER', ID=>'NRepeatGe'.$opts -> {'p'}, Description=>'Filter on n repeats greater or equal then n >= '.$opts -> {'p'}.' .'},
		{key=>'FILTER', ID=>'PASS', Description=>'All filters passed'});
	for my $headerline (@{$headerlines}){
		$vcf -> add_header_line($headerline);
	}
	print {$out} $vcf->format_header();
	#die "header check";
	#$vcf->recalc_ac_an(0);
	warn localtime(time())." [INFO] $0: Iterating records."; my $records=0;
	my %stats;
	while (my $x=$vcf->next_data_hash()){
		#die Dumper($x, $crvheaderline, $annotations,$crvparsed);
		if(not(defined($x -> {'FILTER'} )) or $x -> {'FILTER'} -> [0] eq "." ){
			$x -> {'FILTER'} -> [0] = "PASS";
		}
		my $filters;@{$filters} = ();

		if(defined($opts -> {'r'}) && -e $opts -> {'r'}){
			$x = RepeatAnnotator('record'=> $x,'ref'=> $opts -> {'r'} ,);
			if ($opts -> {'p'}){
				my @repeatCounts = split(',', $x -> {'INFO'} -> {'RepeatCount'});
				for my $repeatCount ( @repeatCounts){
					if($repeatCount >= $opts -> {'p'} ){
						push(@{$filters},'NRepeatGe'.$opts -> {'p'});
						$stats{'filter'}{'NRepeatGe'.$opts -> {'p'}.'Filter'}++;

					}
				}
			}
			
		}
		
		if(defined($annheaderline) && scalar(@{$annheaderline})){
			FillSNPEFFANNFields('record' => $x,'ann' => $annotations);
		}
		#die Dumper($x)." ";
		#setting things up for filtering
		$stats{'EFF'}{$x -> {'INFO'} -> {'SNPEFFANN_ANNOTATION'} }++;
			
			
		#af gnomad filtereing with inclusion of clinvar
		#dbNSFP_gnomAD_exomes_controls_AN
		#dbNSFP_clinvar_clnsig
		if(defined($x -> {'INFO'} -> {'gnomad_v3_1_2_AN'}) && not($x -> {'INFO'} -> {'gnomad_v3_1_2_AN'} eq '') && defined($x -> {'INFO'} -> {'gnomad_v3_1_2_AC'}) && not($x -> {'INFO'} -> {'gnomad_v3_1_2_AC'} eq '')){
			my @GnomadAC = split(',',$x -> {'INFO'} -> {'gnomad_v3_1_2_AC'});
			my $GnomadFiltered=0;
			for my $ac (@GnomadAC){
				if(defined($ac) && not($ac eq '' ) && not($ac eq '.' ) && $x -> {'INFO'} -> {'gnomad_v3_1_2_AN'} != 0){
					if(($ac/$x -> {'INFO'} -> {'gnomad_v3_1_2_AN'}) > $opts -> {'f'}){
						#clinical significance should be present and not matching pathogenic or shouln'd be present.
						if(defined($x -> {'INFO'} -> {'clinvar_CLNSIG'}) && not($x -> {'INFO'} -> {'clinvar_CLNSIG'} eq '' && not(index($x -> {'INFO'} -> {'clinvar_CLNSIG'},'athogenic') > -1  ))){
						
						
							$GnomadFiltered=1;
							push(@{$filters},'AFlt'.$opts -> {'f'}.'Filter');
							$stats{'filter'}{'AFlt'.$opts -> {'f'}.'Filter'}++;
						}elsif(not(defined($x -> {'INFO'} -> {'clinvar_CLNSIG'}) && not($x -> {'INFO'} -> {'clinvar_CLNSIG'} eq ''))){
							$GnomadFiltered=1;
							push(@{$filters},'AFlt'.$opts -> {'f'}.'Filter');
							$stats{'filter'}{'AFlt'.$opts -> {'f'}.'Filter'}++;
						}
					}
				}
			}
		}
		#ideally only run this if official gnomad aint in
		if(defined($x -> {'INFO'} -> {'dbNSFP_gnomAD_exomes_controls_AN'}) && not($x -> {'INFO'} -> {'dbNSFP_gnomAD_exomes_controls_AN'} eq '') && defined($x -> {'INFO'} -> {'dbNSFP_gnomAD_exomes_controls_AC'}) && not($x -> {'INFO'} -> {'dbNSFP_gnomAD_exomes_controls_AC'} eq '')){
                        my @GnomadAC = split(',',$x -> {'INFO'} -> {'dbNSFP_gnomAD_exomes_controls_AC'});
                        my $GnomadFiltered=0;
                        for my $ac (@GnomadAC){
                                if(defined($ac) && not($ac eq '' ) && $x -> {'INFO'} -> {'dbNSFP_gnomAD_exomes_controls_AN'} != 0){
                                        if(($ac/$x -> {'INFO'} -> {'dbNSFP_gnomAD_exomes_controls_AN'}) > $opts -> {'f'}){
                                                #clinical significance should be present and not matching pathogenic or shouln'd be present.
                                                if(defined($x -> {'INFO'} -> {'dbNSFP_clinvar_clnsig'}) && not($x -> {'INFO'} -> {'dbNSFP_clinvar_clnsig'} eq '' && not(index(lc($x -> {'INFO'} -> {'dbNSFP_clinvar_clnsig'}),'athogenic') > -1  ))){


                                                        $GnomadFiltered=1;
                                                        push(@{$filters},'AFlt'.$opts -> {'f'}.'Filter');
                                                        $stats{'filter'}{'AFlt'.$opts -> {'f'}.'Filter'}++;
                                                }elsif(not(defined($x -> {'INFO'} -> {'dbNSFP_clinvar_clnsig'}) && not($x -> {'INFO'} -> {'dbNSFP_clinvar_clnsig'} eq ''))){
                                                        $GnomadFiltered=1;
                                                        push(@{$filters},'AFlt'.$opts -> {'f'}.'Filter');
                                                        $stats{'filter'}{'AFlt'.$opts -> {'f'}.'Filter'}++;
                                                }
                                        }
                                }
                        }
                }

		
		#sumAD filter
		#warn "## sum=".GetSumAD('x' => $x)." ";
		#only for single sample filtering
		my ($sample);
		#sanity check single sample 
		if(defined $opts -> {'n'} && $opts -> {'n'} ne ''){
			if(defined($x -> {'gtypes'} -> {$opts -> {'n'}})){
				$sample = $opts -> {'n'};
			}else{
				die "Invalid samplename specified with -n. Current samplename speicified '".$opts -> {'n'}."' and valid options [".join(',', keys(%{$x -> {'gtypes'}}))."]\n";
			}
		
		}else{
			($sample) = keys(%{$x -> {'gtypes'}});
			die "This is not meant for multisample filtering" if scalar(keys(%{$x -> {'gtypes'}})) != 1; 
		}
		#format of sample present
		if($x -> {'gtypes'} -> {$sample} -> {'GT'} eq './.' && length(keys(%{$x -> {'gtypes'} -> {$sample}})) == 1){
			push(@{$filters},'NoSampleInfo');
			$stats{'filter'}{'NoSampleInfo'}++;
		} 
		#actual filter
		if(defined($x -> {'gtypes'} -> {$sample} -> {'AD'}) && (substr($x -> {'gtypes'} -> {$sample} -> {'AD'},0,1) ne '.')) {
				#my @AD = split(',', $x -> {'gtypes'} -> {$sample} -> {'AD'});
				
				if( GetSumAD('x' => $x,'sample'=> $sample)  < $opts -> {'d'}){
					push(@{$filters},'SumAdlt'.$opts -> {'d'}.'Filter');
					$stats{'filter'}{'SumAdlt'.$opts -> {'d'}.'Filter'}++;
				}
				
		}
		#hetfilter calcs from AD
		if(defined($x -> {'gtypes'} -> {$sample} -> {'AD'}) && (substr($x -> {'gtypes'} -> {$sample} -> {'AD'},0,1) ne '.')){
			my @AD = split(',', $x -> {'gtypes'} -> {$sample} -> {'AD'});
			for my $adval (@AD[1..$#AD]){
				#warn "AD results dump for hetfilter".$AD[0]."\t".$adval."\n";
				if($adval ne '.' && $adval > 0 ){
					if( ($adval/ GetSumAD('x' => $x,'sample'=> $sample))  > $opts -> {'h'}){
										push(@{$filters},'HetGt'.$opts -> {'h'}.'Filter');
										$stats{'filter'}{'HetGt'.$opts -> {'h'}.'Filter'}++;
					}
					if( ($adval/ GetSumAD('x' => $x,'sample'=> $sample)) < $opts -> {'v'}){
													push(@{$filters},'VAFgt'.$opts -> {'v'}.'Filter');
													$stats{'filter'}{'VAFgt'.$opts -> {'v'}.'Filter'}++;
											}
					#if(($adval/GetSumAD('x' =. $x)) < $opts -> {'a'){
					#	push(@{$filters},'AdAltGt'.$opts -> {'a'}.'Filter');
					#	$stats{'filter'}{'AdAltGt'.$opts -> {'a'}.'Filter'}++;
					#
					#}
					if($adval < $opts -> {'a'}){
						push(@{$filters},'AdAltGt'.$opts -> {'a'}.'Filter');
						$stats{'filter'}{'AdAltGt'.$opts -> {'a'}.'Filter'}++;
					}

					
				}elsif($adval == 0 ){
					#zero handling
					#het filter is ok
					
					#alt count filter
							push(@{$filters},'AdAltGt'.$opts -> {'a'}.'Filter');
									$stats{'filter'}{'AdAltGt'.$opts -> {'a'}.'Filter'}++;
					if(defined( $opts -> {'v'})){
							push(@{$filters},'VAFgt'.$opts -> {'v'}.'Filter');
							$stats{'filter'}{'VAFgt'.$opts -> {'v'}.'Filter'}++;
					}

					
				}
				#elsif($adval eq '.'){
				#	#filter on undef???
				#	
				#}else{
				#	#filter on entire field??
				#	#or use af/dp? 
				#}
				
			}
		}
		#also apply HCallerAD
		if(defined($x -> {'gtypes'} -> {$sample} -> {'HCallerAD'}) && (substr($x -> {'gtypes'} -> {$sample} -> {'HCallerAD'},0,1) ne '.')){
			my @AD = split(',', $x -> {'gtypes'} -> {$sample} -> {'HCallerAD'});
			for my $adval (@AD[1..$#AD]){
				#warn "HcCallerAdVals".$AD[0]."\t".$adval."\n";
				if($adval ne '.' && $adval > 0 ){
					if( ($adval/ GetSumHCallerAD('x' => $x,'sample'=> $sample))  > $opts -> {'h'}){
										push(@{$filters},'HetGt'.$opts -> {'h'}.'Filter');
										$stats{'filter'}{'HetGt'.$opts -> {'h'}.'Filter'}++;
					}
					if( ($adval/ GetSumHCallerAD('x' => $x,'sample'=> $sample)) < $opts -> {'v'}){
													push(@{$filters},'VAFgt'.$opts -> {'v'}.'Filter');
													$stats{'filter'}{'VAFgt'.$opts -> {'v'}.'Filter'}++;
											}
					#if(($adval/GetSumHCallerAD('x' =. $x,'sample'=> $sample)) < $opts -> {'a'){
					#	push(@{$filters},'AdAltGt'.$opts -> {'a'}.'Filter');
					#	$stats{'filter'}{'AdAltGt'.$opts -> {'a'}.'Filter'}++;
					#
					#}
					if($adval < $opts -> {'a'}){
						push(@{$filters},'AdAltGt'.$opts -> {'a'}.'Filter');
						$stats{'filter'}{'AdAltGt'.$opts -> {'a'}.'Filter'}++;
					}

					
				}elsif($adval == 0 ){
					#zero handling
					#het filter is ok
					
					#alt count filter
							push(@{$filters},'AdAltGt'.$opts -> {'a'}.'Filter');
									$stats{'filter'}{'AdAltGt'.$opts -> {'a'}.'Filter'}++;
					if(defined( $opts -> {'v'})){
							push(@{$filters},'VAFgt'.$opts -> {'v'}.'Filter');
							$stats{'filter'}{'VAFgt'.$opts -> {'v'}.'Filter'}++;
					}

					
				}				
			}
		}
		
				
		#############effect filtering
		my $snpEffFiltered = 0;
		#my $snpEffPresent = 0;
		#$opts -> {'s'} =~ s///g;
		my @filters = split(',',$opts -> {'s'});
		#warn  "Err here".Dumper(@filters)." ";
		#compare multiple filters with 1 or more effects if not matched blabla
		for my $eff (split(/[,\&]/,$x -> {'INFO'} -> {'SNPEFFANN_ANNOTATION'})){
			my $effsfiltered = 1;
			for my $filter (@filters){
				#die "Err here".Dumper(split(/[,\&]/,$x -> {'INFO'} -> {'SNPEFFANN_ANNOTATION'}),$x -> {'INFO'} -> {'SNPEFFANN_ANNOTATION'})." " if($x -> {'INFO'} -> {'SNPEFFANN_ANNOTATION'} =~ m/[,\&]/ && $x -> {'INFO'} -> {'SNPEFFANN_ANNOTATION'} =~ m/missense/);
				if($eff eq $filter){#This test for annotations present on a negative inclusion list.
					$effsfiltered = 0;
				}
			}
			#When one or more less harmfull catergories are found set to 0 so this is the minimal list of all harmfull effect snps. Assuming the SNPEFFANN_ANNOTATION only contains the most harmfull is ok?
			if($effsfiltered == 1){
				$snpEffFiltered = 1;
			}
		}
		if($snpEffFiltered == 0){
			push(@{$filters},'EffFilter');
			$stats{'filter'}{'EffFilter'}++;
		}
			
		##caddd filtering 10?
		#regular
		if (defined($x -> {'INFO'} -> {'CADD_SCALED'}) && not($x -> {'INFO'} -> {'CADD_SCALED'} eq '')){ 
			my @caddexomephred = split(',',$x -> {'INFO'} -> {'CADD_SCALED'});
			for my $cadd (@caddexomephred){
				if(defined($cadd) && not($cadd eq '')){
					if($cadd < $opts -> {'c'}){
						push(@{$filters},'CaddPred'.$opts -> {'c'}.'Filter');
						$stats{'filter'}{'CaddPred'.$opts -> {'c'}.'Filter'}++;
					}
				}
			}
		} elsif (defined($x -> {'INFO'} -> {'dbNSFP_CADD_phred'}) && not($x -> {'INFO'} -> {'dbNSFP_CADD_phred'} eq '')){ 
			#dbnsf field dbNSFP_CADD_phred
			my @caddexomephred = split(',',$x -> {'INFO'} -> {'dbNSFP_CADD_phred'});
			for my $cadd (@caddexomephred){
				if(defined($cadd) && not($cadd eq '')){
					if($cadd < $opts -> {'c'}){
						push(@{$filters},'CaddPred'.$opts -> {'c'}.'Filter');
						$stats{'filter'}{'CaddPred'.$opts -> {'c'}.'dbNSFP_Filter'}++;
					}
				}
			}
		}
		#HCallerFS
		if (defined($x -> {'INFO'} -> {'HCallerFS'}) && not($x -> {'INFO'} -> {'HCallerFS'} eq '')){ 
			my @hcfs = split(',',$x -> {'INFO'} -> {'HCallerFS'});
			for my $hcfs (@hcfs){
				if(defined($hcfs) && not($hcfs eq '')){
					if($hcfs > $opts -> {'f'}){
						push(@{$filters},'HcFisherStrand'.$opts -> {'s'}.'Filter');
						$stats{'filter'}{'HcFisherStrand'.$opts -> {'s'}.'Filter'}++;
					}
				}
			}
		}
		#HCallerMQ
		#if (defined($x -> {'INFO'} -> {'HCallerMQRankSum'}) && not($x -> {'INFO'} -> {'HCallerMQRankSum'} eq '')){ 
		#	my @mqrss = split(',',$x -> {'INFO'} -> {'HCallerMQRankSum'});
		#	for my $mqrs (@mqrss){
		#		if(defined($mqrs) && not($mqrs eq '')){
		#			if($mqrs < $opts -> {'m'}){
		#				push(@{$filters},'HcMQRankSum'.$opts -> {'m'}.'Filter');
		#				$stats{'filter'}{'HcMQRankSum'.$opts -> {'m'}.'Filter'}++;
		#			}
		#		}
		#	}
		#}
		if((not(defined($x -> {'FILTER'})) or $x -> {'FILTER'} -> [0] eq "." or $x -> {'FILTER'} -> [0] eq "PASS") && scalar(@{$filters}) > 0){
				@{$x -> {'FILTER'}}= @{$filters};#replace filter
			}elsif(scalar(@{$filters}) > 0){
				#$x -> [6] .= ';'.join(';',@{$filters});
				push(@{$x -> {'FILTER'}},@{$filters});
			}
		print {$out} $vcf->format_line($x);
		$records++;
		#if(defined($x -> {'gtypes'} -> {$sample} -> {'AD'}) && (substr($x -> {'gtypes'} -> {$sample} -> {'AD'},0,1) ne '.') && defined( $opts -> {'a'})){
		#		my @ad;@ad = split(',',$x -> {'gtypes'} -> {$sample} -> {'AD'});
		#		print {$csv} join(',',(join(";",@{$x -> {'FILTER'}}),GetSumAD('x' => $x),$ad[0],$ad[1],$ad[1]/GetSumAD('x' => $x)))."\n" if(GetSumAD('x' => $x) > 0);
		#}
	}
	
	
#               if(scalar(@{GetAlt($x)})>1){
#				die Dumper($x)."\n".GetAlt($x)."\n".$. ;
#		}
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
	my @samples = keys(%{$record -> {'gtypes'}}); 
	my $sample;
	if(defined( $self -> {'sample'} )){
		$sample = $self -> {'sample'};
	}else{
		$sample = $samples[0];
	}
	#die "Genotype count > 1 this aint ment for filtering multiple samples in a single vcf amount of (vcf) columns " if scalar(@{$record}) > 10;
	#my $format = $record -> {'gtypes'}; my $gtinfo = $record -> [9];
	#my $gt;
	#@{$gtypes} = split(':',$gtinfo);
	#my $gtparsed;
	#map{$gtparsed -> {$_} = shift(@{$gt});}(split(":",$format));
	#warn Dumper($gtparsed);
	#my @samples = keys(%{$record -> {'gtypes'}}); 
	#die "Genotype count > 1 this aint ment for filtering multiple samples in a single vcf amount of (vcf) columns " if(scalar(@samples)>1); 
	my $sum = 0;
	map{$sum += $_;}(split(',',$record -> {'gtypes'} -> {$sample} -> {'AD'}));
	return $sum;
}
sub GetSumHCallerAD {
	my $self;
	%{$self}= @_;
	my $record = $self -> {'x'};
	my @samples = keys(%{$record -> {'gtypes'}}); 
	my $sample;
	if(defined( $self -> {'sample'} )){
		$sample = $self -> {'sample'};
	}else{
		$sample = $samples[0];
	}
	#die "Genotype count > 1 this aint ment for filtering multiple samples in a single vcf amount of (vcf) columns " if scalar(@{$record}) > 10;
	#my $format = $record -> {'gtypes'}; my $gtinfo = $record -> [9];
	#my $gt;
	#@{$gtypes} = split(':',$gtinfo);
	#my $gtparsed;
	#map{$gtparsed -> {$_} = shift(@{$gt});}(split(":",$format));
	#warn Dumper($gtparsed);
	#die "Genotype count > 1 this aint ment for filtering multiple samples in a single vcf amount of (vcf) columns " if(scalar(@samples)>1); 
	my $sum = 0;
	map{$sum += $_;}(split(',',$record -> {'gtypes'} -> {$sample} -> {'HCallerAD'}));
	return $sum;
}
#sub GetCrvFunctionalAnnotations {
#	my $crvParsed = shift @_ or die "no input given for subroutine";
#	die "invalid input".Dumper($crvParsed) if(not(defined($crvParsed -> [0] -> {'Description'})));
#	my $crvdescr = $crvParsed -> [0] -> {'Description'};
#	$crvdescr =~ s/Functional\ annotations\:\ \'|\'//g;
#	my $crvdescrvcf = $crvdescr;
#	$crvdescrvcf =~ s/ \/ /_AND_/g;
#	$crvdescrvcf =~ s/\./_/g;
#	
#	my $annotations;
#	#@{$annotations}
#	
#	my @anns = split('\|', $crvdescr);
#	my @crvsVcf = split('\|', $crvdescrvcf);
#	for my $crvVcf (@crvsVcf){
#		my $ann = shift(@anns);
#		my ($name) = split('=',$crvVcf); 
#		my %h = ('name' => uc($name),'alias' => $ann);
#		#this is BS reporting fields in the header but never outputting them!#!4!#%%#$^$%&*
#		if(substr($name,0,9) ne 'vcfinfo__'){
#					push(@{$annotations},\%h);
#		}
#	}
#
 #   return $annotations;
#}
sub GetAnnFunctionalAnnotations {
	my $annParsed = shift @_ or die "no input given for subroutine";
	die "invalid input".Dumper($annParsed) if(not(defined($annParsed -> [0] -> {'Description'})));
	my $anndescr = $annParsed -> [0] -> {'Description'};
	$anndescr =~ s/Functional\ annotations\:\ \'|\'//g;
	my $anndescrvcf = $anndescr;
	$anndescrvcf =~ s/ \/ /_AND_/g;
	$anndescrvcf =~ s/\./_/g;
	
	my $annotations;
	#@{$annotations}
	
	my @anns = split(' \| ', $anndescr);
	my @annsVcf = split(' \| ', $anndescrvcf);
	for my $annVcf (@annsVcf){
		my $ann = shift(@anns);
		my %h = ('name' => uc($annVcf),'alias' => $ann);
		push(@{$annotations},\%h);
	}

    return $annotations
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
	if(index($alt,'*') > -1){
		my $spanningDeletionAnn = '*'.'|.'  x (scalar(@{$annotations}) - 1);
		push(@anns,$spanningDeletionAnn);
	}
	
	my $worstAnn;
	
	while(not(defined($worstAnn))){
		#warn "what doe this return and where do the undefs come from, tldr bad practice to write code as `something if(test)`". Dumper(@anns,"test",split(",",GetAnn($r)))." ";
		my $ann = shift @anns;
		if (GetAnnotationAllele('annfields' => [$ann],'ann' => $annotations) eq $alt || (length(GetAnnotationAllele('annfields' => [$ann],'ann' => $annotations)) + 1 == length($alt) && GetAnnotationAllele('annfields' => [$ann],'ann' => $annotations) eq substr($alt,1))){
			$worstAnn = $ann;#first assumed to be the worst possible annotation
			#die Dumper($worstAnn)
		}elsif(scalar(@anns) == 0 ){ #with 'REF' => 'GCCCGCA' and ALT 'GCCCCGCC' this gets nasty does it need the first base (aka is it an MNP, what is the minimal presentation, do i want to calculate this)?? 
			$worstAnn = $ann;
		}else{
			$worstAnn = $ann; # I gave up also multiallelics are split in my workflow.;
			#die "Infinte loop stopper:".Dumper(\$ann,\$annotations,\$self,"here",\@anns,"here",$worstAnn).' ';
		}
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
		my @anns = split(/\|/,$annField,-1);
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
	my $annField = @{$self -> {'annfields'}}[0] or die "no annotations object value as input".Dumper($self)." " ;
	my $annotationHeader = $self -> {'ann'} or die "no annotations object value as input";
	my $parsed = ParseAnnotation(%{$self});
	for my $annotation (@{$parsed}){
		return $annotation -> {'values'} -> [0] if($annotation -> {'name'} eq 'ALLELE' && scalar(@{$annotation -> {'values'}}) == 1);
	}
}


sub text {

print "coding_sequence_variant
chromosome
duplication
inversion
coding_sequence_variant
inframe_insertion
disruptive_inframe_insertion
inframe_deletion
disruptive_inframe_deletion
downstream_gene_variant
exon_variant
exon_loss_variant
exon_loss_variant
duplication
duplication
inversion
inversion
frameshift_variant
gene_variant
feature_ablation
duplication
gene_fusion
gene_fusion
bidirectional_gene_fusion
rearranged_at_DNA_level
intergenic_region
conserved_intergenic_variant
intragenic_variant
intron_variant
conserved_intron_variant
miRNA
missense_variant
initiator_codon_variant
stop_retained_variant
protein_protein_contact
structural_interaction_variant
rare_amino_acid_variant
splice_acceptor_variant
splice_donor_variant
splice_region_variant
splice_region_variant
splice_region_variant
stop_lost
5_prime_UTR_premature_
start_codon_gain_variant
start_lost
stop_gained
synonymous_variant
start_retained
stop_retained_variant
transcript_variant
feature_ablation
regulatory_region_variant
upstream_gene_variant
3_prime_UTR_variant
3_prime_UTR_truncation + exon_loss
5_prime_UTR_variant
5_prime_UTR_truncation + exon_loss_variant
sequence_feature + exon_loss_variant";

print "coding_sequence_variant","downstream_gene_variant","exon_variant","gene_variant","duplication","intergenic_region","conserved_intergenic_variant","intragenic_variant","intron_variant","conserved_intron_variant","initiator_codon_variant","stop_retained_variant","5_prime_UTR_premature_start_codon_gain_variant","start_retained","stop_retained_variant","3_prime_UTR_truncation + exon_loss","5_prime_UTR_truncation + exon_loss_variant","sequence_feature + exon_loss_variant";
}

sub CmdRunner {
    my $ret;
    my $cmd = join(" ",@_);

    #warn localtime( time() ). " [INFO] system call:'". $cmd."'.\n";

    @{$ret} = `($cmd )2>&1`;
    if ($? == -1) {
        die localtime( time() ). " [ERROR] failed to execute: $!\n system call:'". $cmd."'.\n";
    }elsif ($? & 127) {
        die localtime( time() ). " [ERROR] " .sprintf "child died with signal %d, %s coredump. system call:'". $cmd."'.\n",
         ($? & 127),  ($? & 128) ? 'with' : 'without';
    }elsif ($? != 0) {
        die localtime( time() ). " [ERROR] " .sprintf "child died with signal %d, %s coredump. system call:'". $cmd."'.\n",
             ($? & 127),  ($? & 128) ? 'with' : 'without';
    }else {
        #warn localtime( time() ). " [INFO] " . sprintf "child exited with value %d\n", $? >> 8;
    }
    return @{$ret};
}

sub RepeatAnnotator {
	my $self;
	%{$self}= @_;
	my $record = $self -> {'record'};
	my $ref = $self -> {'ref'};
	my $window = 30;#Window size should be smaller then 40 due to clipping 
	my @fa = CmdRunner('set -o pipefail && echo -e "' .
		$record -> {'CHROM'}.'\t' .
		($record -> {'POS'} - $window - 1 ) .'\t' .
		($record -> {'POS'} + $window + length($record -> {'REF'})).'"| bedtools getfasta -fi '.
		$ref .
		' -bed /dev/stdin -fo /dev/stdout');
	my $selectionBefore = substr($fa[1],0,$window);
	my $selectionAfter = substr($fa[1],$window+length($record -> {'REF'}),$window);
	#warn (join("\n",($fa[1],$selectionBefore,substr($fa[1],$window,length($record -> {'REF'})),$selectionAfter,join("_",($selectionBefore,substr($fa[1],$window,length($record -> {'REF'})),$selectionAfter))))," ");
	#AGCCTGGGCAACAGAGCGAGACTCCATCTC AAAAAA AAAAAAAAAAGAAATGAGAGTAATGTAATA
	#AGCCTGGGCAACAGAGCGAGACTCCATCTC_AAAAAA_AAAAAAAAAAGAAATGAGAGTAATGTAATA
	#AGCCTGGGCAACAGAGCGAGACTCCATCTC
	#AAAAAA
	#AAAAAAAAAAGAAATGAGAGTAATGTAATA
	#  at /groups/umcg-pmb/tmp01//umcg-mterpstra/git/molgenis-c5-TumorNormal/scripts/VcfSnpEffAnnoFilter.pl line 664, <__ANONIO__> line 4262.

	$record -> {'INFO'} -> {'RepeatCount'} = "1".",1" x scalar(@{$record -> {'ALT'}});
	$record -> {'INFO'} -> {'RepeatCountRepeatUnit'} = ($record -> {'REF'}.",".join(',',@{$record -> {'ALT'}}));
	my @RepeatCounts;
	my @RepeatCountsRepeatUnit;

	for my $ref (($record -> {'REF'})){
		my $maxRepeat = 1;
		my $maxRepeatUnit = $ref;
		for my $index (0..2){
			for my $offset (1..length($ref)+3){
				my ($repeatCount, $repeatUnit) = findRepeat('seq'=>$ref.$selectionAfter,'index'=>$index,'offset'=>$offset);
				#die Dumper($record). " ";
				#die ("'seq'=>$ref.$selectionAfter,'index'=>$index,'offset'=>$offset",Dumper($record))if($record -> {'REF'} eq "AGCG" );
				if($repeatCount >= $maxRepeat && $repeatCount > 1){
					$maxRepeat = $repeatCount;
					$maxRepeatUnit = $repeatUnit;
					#die Dumper($record, \@fa, \$selectionBefore,\$selectionAfter,\$basicSubunit, \$maxrepeat)
				}
				my ($repeatCountRev, $repeatUnitRev) = findRepeat('seq'=>reverse($selectionBefore.$ref),'index'=>$index,'offset'=>$offset);
				if($repeatCountRev >= $maxRepeat && $repeatCountRev > 1){
					$maxRepeat = $repeatCountRev;
					$maxRepeatUnit = reverse($repeatUnitRev);
					#die Dumper($record, \@fa, \$selectionBefore,\$selectionAfter,\$basicSubunit, \$maxrepeat)." ";
				}
				#AAAAATGTCAGTCAGCGCCCCGGGGAGCAGCCGAGGGTCCC
				#AAAAATGTCAGTCAGCGCCC
				#                     GGGGAGCAGCCGAGGGTCCC
			}
			#warn(" ")if($maxRepeatUnit)
		}
		
		push(@RepeatCounts, $maxRepeat);
		push(@RepeatCountsRepeatUnit, $maxRepeatUnit);
	}
	for my $alt (@{$record -> {'ALT'}}){
		
		#die Dumper($record, \@fa, \$selectionBefore,\$selectionAfter);
		#will dump someting like:
		#$VAR1{
		#	...
		#	'ALT' => [
        #		'A'
        #		],
        #	'REF' => 'C',
		#	...
		#}
		#$VAR3 = [
        #	'>chr1:2556204-2556245
		#',
        #	'AAAAATGTCAGTCAGCGCCCCGGGGAGCAGCCGAGGGTCCC
		#'
        #];
		#$VAR4 = \'AAAAATGTCAGTCAGCGCCC';
		#$VAR5 = \'GGGGAGCAGCCGAGGGTCCC';
		#comparing gives
		#AAAAATGTCAGTCAGCGCCCCGGGGAGCAGCCGAGGGTCCC
		#AAAAATGTCAGTCAGCGCCC
		#                     GGGGAGCAGCCGAGGGTCCC

		my $maxRepeat = 1;
		my $maxRepeatUnit = $alt;
		for my $index (0..2){
			for my $offset (1..length($alt)+3){
				my ($repeatCount, $repeatUnit) = findRepeat('seq'=>$alt.$selectionAfter,'index'=>$index,'offset'=>$offset);
				if($repeatCount >= $maxRepeat && $repeatCount > 1){
					$maxRepeat = $repeatCount;
					$maxRepeatUnit = $repeatUnit;
					#die Dumper($record, \@fa, \$selectionBefore,\$selectionAfter,\$basicSubunit, \$maxrepeat)." ";
				}
				#AAAAATGTCAGTCAGCGCCCCGGGGAGCAGCCGAGGGTCCC
				#AAAAATGTCAGTCAGCGCCC
				#                     GGGGAGCAGCCGAGGGTCCC
				my ($repeatCountRev, $repeatUnitRev) = findRepeat('seq'=>reverse($selectionBefore.$alt),'index'=>$index,'offset'=>$offset);
				if($repeatCountRev >= $maxRepeat && $repeatCountRev > 1){
					$maxRepeat = $repeatCountRev;
					$maxRepeatUnit = reverse($repeatUnitRev);
					#die Dumper($record, \@fa, \$selectionBefore,\$selectionAfter,\$basicSubunit, \$maxrepeat)." ";
				}
				#AAAAATGTCAGTCAGCGCCCCGGGGAGCAGCCGAGGGTCCC
				#AAAAATGTCAGTCAGCGCCC
				#                     GGGGAGCAGCCGAGGGTCCC
			}
		}
		#ideally they should be left assigned so the before shouldnt be used at all
		#if(
		#	$selectionAfter =~ m/^(A){2,}/ |
		#	$selectionAfter =~ m/^(C){2,}/ |
		#	$selectionAfter =~ m/^(G){2,}/ | 
		#	$selectionAfter =~ m/^(T){2,}/ 
		#){
		#	my $basicMatch = $1;
		#	my $fullLength = $&;
		#	my $repeatLength = length($fullLength)/length($basicMatch);
		#	die Dumper($record, \@fa, \$selectionBefore,\$selectionAfter,\$basicMatch,\$fullLength, \$repeatLength);
		#}

		push(@RepeatCounts, $maxRepeat);
		push(@RepeatCountsRepeatUnit, $maxRepeatUnit);

	}
	$record -> {'INFO'} -> {'RepeatCount'} = (join(',',@RepeatCounts));
	$record -> {'INFO'} -> {'RepeatCountRepeatUnit'} = (join(',',@RepeatCountsRepeatUnit));
	return $record;
}

sub findRepeat{
	my $self;
	%{$self}= @_;
	#finds repeats in the start of the sequence starting at index-offset and sees if it is repeated by returning repeatcount and repeatunit
	my $index = $self -> {'index'};
	my $offset = $self -> {'offset'};
	my $seq = $self -> {'seq'};
	my $repeatUnit = substr($seq,$index,$offset);
	my $repeatCount = 0;
	while(index($seq,$repeatUnit,$index)==$index){
		$repeatCount++;
		$index += $offset;
		#warn(index($alt.reverse($selectionBefore),$basicSubunit,$index)."Here");
	}
	return ($repeatCount,$repeatUnit);
}
