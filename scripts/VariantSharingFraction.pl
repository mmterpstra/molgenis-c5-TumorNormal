#!/usr/bin/perl
use strict;
use warnings;
my $use = <<"END1";
Use $0  FILE(s)
	Human VCF FILE accepted as input
END1


if (scalar(@ARGV)==0){
	print $use;
	exit(0);
}
my $file = $ARGV[0];
(die "$0:file does not exist!(-e)\n$!")if(not(-e $file));
my $wcl = `wc -l ${file}`;
chomp($wcl);
$wcl =~ s/\s.*$//;
open(my $in,'<', "${file}") or die "Read error of $file!!!\n $!";

my $headerline = "##";
#description line removal
while($headerline =~ /^##/){
	$headerline = <$in>;	
	chomp($headerline);
}

#header line processingk
my $sampleCount;
my @sampleNames;
my $formatColumn;
my @header;
if($headerline =~ /^#/){
	$headerline =~ s/#//;
	@header = split('	',$headerline);
	print STDERR "\t".$headerline."\n";
	for (my $i=0; $i<scalar(@header); $i++){
		if($header[$i] eq 'FORMAT'){
			$formatColumn = $i;	
		}
		if($header[$i] eq ''){
			splice(@header,$i);
			$i--;#if $i<scalar(@header) is continuosly evaluated this shouldn't go wrongish... 
		}
	}
	$sampleCount = 	scalar(@header)	- $formatColumn - 1;#$formatColumn is zero based
	@sampleNames = @header[($formatColumn+1)..(scalar(@header)-1)];
}else{
	die "vcf header line not found the input file, migth not be a vcf file or is poorly formatted\n$!\n";
}

my %sampleCounts;
my %venn2wdata;
my %venn3wdata;
my $line;
my $prev;
while($line = <$in>){
	chomp($line);
	$prev = $line;
	print STDERR "###".localtime(time())."### VariantSharing Calculation: doing line '${.}' of '${wcl}'\n" if($. =~ /\d{1,}0000$/);
	my @vcf = split('	',$line);
	for(my $i = ($formatColumn+1); $i < ($formatColumn+1+$sampleCount); $i++){
		if(substr($vcf[$i],0,3) ne './.'){
			$sampleCounts{$header[$i]}++;
		}		
		for(my $i2=($formatColumn+1); $i2<($formatColumn+1+$sampleCount); $i2++){
			if($i != $i2){
				if(substr($vcf[$i],0,3) eq  substr($vcf[$i2],0,3) && substr($vcf[$i2],0,3) ne './.'){
					$venn2wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}++;
				}
			}
			for(my $i3=($formatColumn+1); $i3<($formatColumn+1+$sampleCount); $i3++){
				if($i != $i2 && $i2 != $i3 && $i != $i3){
					if(substr($vcf[$i],0,3) eq  substr($vcf[$i2],0,3) && substr($vcf[$i],0,3) eq  substr($vcf[$i3],0,3) && substr($vcf[$i3],0,3) ne './.'){
						$venn3wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}{'>3'}{$header[$i3]}++;
					}
				}
			}
		}
	}
}
for my $key (sort(keys(%sampleCounts))){
	print STDOUT "$key\t".$sampleCounts{$key}."\n";
}

for(my $i = ($formatColumn+1); $i < ($formatColumn+1+$sampleCount); $i++){
	for(my $i2=($formatColumn+1); $i2<($formatColumn+1+$sampleCount); $i2++){
		if($venn2wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}){
			my $RpairwiseVenn = "draw.pairwise.venn(area1 = $sampleCounts{$header[$i]}, area2 = $sampleCounts{$header[$i2]}, cross.area = $venn2wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}, category = c('$header[$i]', '$header[$i2]'), fill = c('blue', 'red'), lty = 'blank', cex = 2, cat.cex = 2, cat.pos = c(285, 105), cat.dist = 0.09, cat.just = list(c(-1, -1), c(1, 1)), ext.pos = 30, ext.dist = -0.05, ext.length = 0.85, ext.line.lwd = 2, ext.line.lty = 'dashed');plot.new()";
			print STDOUT "$header[$i] vs $header[$i2]\t$header[$i]\t$header[$i2]\t".$sampleCounts{$header[$i]}."\t".$sampleCounts{$header[$i2]}."\t".$venn2wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}."\t$RpairwiseVenn"."\n";
			#print STDOUT "draw.pairwise.venn(65, 75, 35, c("First", "Second"))"
		}
	}
}
for(my $i = ($formatColumn+1); $i < ($formatColumn+1+$sampleCount); $i++){
	for(my $i2=($formatColumn+1); $i2<($formatColumn+1+$sampleCount); $i2++){
		for(my $i3=($formatColumn+1); $i3<($formatColumn+1+$sampleCount); $i3++){
			if($venn3wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}{'>3'}{$header[$i3]}){
				my $RtripleVenn="draw.triple.venn( area1 = $sampleCounts{$header[$i]},  area2 = $sampleCounts{$header[$i2]},  area3 = $sampleCounts{$header[$i3]}, n12 = $venn2wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}, n23 = $venn2wdata{'>1'}{$header[$i2]}{'>2'}{$header[$i3]}, n13 = $venn2wdata{'>1'}{$header[$i]}{'>2'}{$header[$i3]}, n123 = $venn3wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}{'>3'}{$header[$i3]}, category = c('$header[$i]', '$header[$i2]', '$header[$i3]'), fill = c('blue', 'red', 'green'), lty = 'blank', cex = 2, cat.cex = 2, cat.col = c('blue', 'red', 'green') )";
				#print STDOUT "$header[$i] vs $header[$i2] vs $header[$i3]\t".$venn3wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}{'>3'}{$header[$i3]}."\n";
				print STDOUT "$header[$i] vs $header[$i2] vs $header[$i3]\t".$venn3wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}{'>3'}{$header[$i3]}."\t".$sampleCounts{$header[$i]}."\t".$sampleCounts{$header[$i2]}."\t".$sampleCounts{$header[$i3]}."\t".$venn2wdata{'>1'}{$header[$i]}{'>2'}{$header[$i2]}."\t".$venn2wdata{'>1'}{$header[$i2]}{'>2'}{$header[$i3]}."\t".$venn2wdata{'>1'}{$header[$i3]}{'>2'}{$header[$i]}."\t$RtripleVenn\n";
			}
		}
	}
}
print STDOUT "dev.off()\n";
my @vcf = split('	',$prev);
print STDERR "###".localtime(time())."### VariantSharing Calculation: done at '$vcf[0],$vcf[1]' line '${.}' of '${wcl}'\n";
