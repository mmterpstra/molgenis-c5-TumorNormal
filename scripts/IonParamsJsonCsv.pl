#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
#use Scalar::Util qw(looks_like_number);
use Carp qw(confess carp croak cluck);
use Getopt::Long;
use JSON;

my $opts;
sub Defaults {
	%{$opts} = ('j'	=> './ion_params_00.json',
				'c'=> './ion_params_00.csv');
}

GetOptions ("json|j=s"   => \$opts -> {'j'},      # string
	"csv|c=s"   => \$opts -> {'c'},
	"help|h=s"   => \$opts -> {'h'},
	"validate=s"	=> \$opts -> {'v'},
	"version|v=s"  => \$opts -> {'V'},
	) or die("Error in command line arguments\n");

my $VERSION = '0.0.1';

my $USE = "$0 --json ./ion_params_00.json --csv ./ion_params_00.csv\n converts iontorrent ion_params.json to csv";

(print "$0 version $VERSION" && exit) if($opts -> {'V'});
(print "$USE" && exit) if($opts -> {'h'});

main();

sub main {
	die "no valid input. $USE" if(not(-e $opts -> {'j'})); 
	#die Dumper(ReadJSON($opts -> {'j'}));
	warn "## Init ## ".localtime(time())." ## converting '".$opts -> {'j'}."'";
	my $csv = PopulateCSVWithJSON($opts -> {'j'});
	my $csvHandle = *STDOUT;
	if(defined($opts -> {'c'})){
			open($csvHandle,'>',$opts -> {'c'}) or die "Cannot open csv" ;
	}
	print $csvHandle CsvAsString($csv);
	warn "## Done ## ".localtime(time())." ## finished converting '".$opts -> {'j'}."'";	
}

sub ReadJSON {
	my $file = shift(@_) or die "no input to subroutine";
	#from json perl module manual 'how to decode # from file content'
	local $/;
	open( my $fh, '<', $file )or die "invalid file";
	my $json_text   = <$fh>;
	#$json_text =~ s!\\!!g;
	#$json_text =~ s/\\+"/"/g;
	#$json_text =~ s/"\{/\{/g;
	#$json_text =~ s/"\}/\}/g;
	#warn $1;
	#print $json_text."\n";
	my $perl_scalar = decode_json( $json_text );
	#die Dumper(\$json_text,$perl_scalar)." ";	
	return $perl_scalar;
}
sub FixJsonDecode {
	my $r  = shift @_ or confess "Error here".Dumper(@_)." ";
	if(not(ref($r)) && $r =~ m/^\{.*\}$/){
		$r=decode_json( $r ) or die "Cannot decode json, tried, tried again and failed";
		#die "Does this work".Dumper($r);
	}
	#die Dumper($r)." ";
	return $r;
}
sub PopulateCSVWithJSON {
	my $jsonfile = shift @_ or die "no input";
	my $obj;
	my $csv;
	$obj -> {'data'} = ReadJSON($jsonfile);
	$obj -> {'meta'} -> {'file'} = $jsonfile;
	if(ref($obj -> {'data'}) eq 'ARRAY'){
		$obj -> {'meta'} -> {'fileformat'} = 'A';#starts with array
		$csv = SetSerialSampleMetaCsv($obj,$csv);
		$csv = SetSerialSampleInfoCsv($obj,$csv);
	}elsif(ref($obj -> {'data'}) eq 'HASH'){
		$obj -> {'meta'} -> {'fileformat'} = 'H';#starts with hash
		$csv = SetSampleMetaCsv($obj,$csv);
		$csv = SetSampleInfoCsv($obj,$csv);
	}else{
		die "What is this? Dumper($obj). ";
	}

	return $csv;
	
}
sub SetSerialSampleMetaCsv {
	my ($obj,$csv)  = @_;
	for my $sample (GetSerialObjSampleNames($obj)){
		#the 'sampleDisplayedName' is needed later on with samplebarcode props
		push(@{$csv},{'meta' => {'sample' => $sample, 'file' => GetObjFile($obj),'sampleDisplayedName' => GetSerialObjDispName($obj,$sample)}});
	}
	return $csv;	
}

sub GetSerialObjSampleNames {
	my $obj=shift(@_);
	#warn Dumper($obj -> {'data'})." " if(defined($obj -> {'data'}));

	#find something like this and parse it:
		#{
		#  "pk": 9001, 
		#  "model": "rundb.sample", 
		#  "fields": {
		#    "status": "run", 
		#    "name": "JohnDoe",  <<<<===-- get this one!!!!
		#    "displayedName": "JohnDoe", 
		#    "experiments": [
		#      9001
		#    ], 
		#    "externalId": "", 
		#    "date": "2000-01-30T12:12:12.000Z", 
		#    "description": ""
		#  }
		#},
	
	my @samples;my $samples;
	for my $db (GetSerialObjDbs($obj,'rundb.sample')){
		my $sample = $db -> {'fields'} -> {'name'};
		push(@samples,$sample);
		$samples -> {$db -> {'fields'} -> {'name'}}++; 			
	}
	warn "INFO found ".scalar(@samples)." samples with ".scalar(keys(%{$samples}))." unique names\n";
	die "ERROR No samples found ".Dumper($obj)." " if(not(scalar(@samples)));

	return @samples; 
	#try other location with sampleinformation
}

sub GetSerialObjDispName {
	my $obj=shift(@_);
	my $name= shift(@_);
	my $dispname;
	my @samples = GetSerialObjDbs($obj,'rundb.sample');
	for my $sample (@samples){
		return $sample -> {'fields'} -> {'displayedName'} if($sample -> {'fields'} -> {'name'} eq $name);
	}
	warn "Warning no displayedname found using defult name.";
	return $name ;
}

sub GetSerialObjDbs{
	#returns an array of stuff you want to test
	my ($obj,$dbquery)  = @_;
	my @res;
	for my $db (@{$obj -> {'data'}}){
		if($db -> {'model'} eq $dbquery){
			
			push @res,$db;						
		}
	}
	die "ERROR Could not find dbquery '$dbquery' on obj ".Dumper($obj) . "  " if(not(scalar(@res)));

	return @res;
}

sub GetSerialObjDb{
	my @ret = GetSerialObjDbs(@_);
	my ($obj,$dbquery)  = @_;
	die "Invalid amount expected 1 got ".scalar(@ret)." results from dbquery '$dbquery' on obj ".Dumper($obj) . "  " if(not(scalar(@ret) == 1));
	return $ret[0];
}

sub SetSerialSampleInfoCsv {
	my ($obj, $csv)  = @_;
	my $csvNew;
	for my $sampleObj (@{$csv}){
		#warn Dumper($sampleObj)." ";
		
		#$obj -> {'data'} -> {'sampleInfo'}=FixJsonDecode($obj -> {'data'} -> {'sampleInfo'});
		$sampleObj -> {'data'} -> {'sampleName'} = $sampleObj -> {'meta'} -> {'sample'};
		#first get the most important sampleinfo
		my $expanaset = GetSerialObjDb($obj,'rundb.experimentanalysissettings');
			#{
			#  "pk": 248, 
			#  "model": "rundb.experimentanalysissettings", 
			#  "fields": {
			#    "ionstatsargs": "ionstats alignment", 
			#    "isEditable": false, 
			#    "endBarcodeKitName": "", 
			#    "hotSpotRegionBedFile": "", 
			#    "mixedTypeRNA_reference": "", 
			#    "analysisargs": "Analysis --args-json /opt/ion/config/args_316v2_analysis.json --gopt /opt/ion/config/gopt_316v2_Hi-Q.param.json", 
			#    "targetRegionBedFile": "/results/uploads/BED/1/hg19/unmerged/detail/data_Designed.bed", 
			#    "thumbnailalignmentargs": "", 
			#    "thumbnailanalysisargs": "", 
			#    "barcodedSamples": "{\"JohnDoe1\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_012\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_012\"]},\"JohnDoe2\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_015\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_015\"]},\"JohnDoe3\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_007\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_007\"]},\"JohnDoe4\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_014\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_014\"]},\"JohnDoe5\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_010\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_010\"]},\"JohnDoe6\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_009\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_009\"]},\"JohnDoe7\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_011\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_011\"]},\"JohnDoe8\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_013\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_013\"]},\"JohnDoe9\":{\"dualBarcodes\":[],\"barcodeSampleInfo\":{\"IonXpress_008\":{\"description\":\"\",\"reference\":\"hg19\",\"hotSpotRegionBedFile\":\"\",\"nucleotideType\":\"DNA\",\"targetRegionBedFile\":\"/results/uploads/BED/1/hg19/unmerged/detail/IAD96087_167_Designed.bed\",\"controlSequenceType\":\"\",\"externalId\":\"\",\"endBarcode\":\"\",\"controlType\":\"\",\"sseBedFile\":\"\"}},\"barcodes\":[\"IonXpress_008\"]}}", 
			#    "custom_args": false, 
			#    "reference": "hg19", 
			#    "isOneTimeOverride": false, 
			#    "mixedTypeRNA_hotSpotRegionBedFile": "", 
			#    "mixedTypeRNA_targetRegionBedFile": "", 
			#    "thumbnailcalibrateargs": "", 
			#    "realign": false, 
			#    "selectedPlugins": "{\"DataExport\":{\"userInput\":\"\",\"version\":\"5.8.0.2\",\"id\":92,\"name\":\"DataExport\",\"features\":[]},\"ERCC_Analysis\":{\"userInput\":\"\",\"version\":\"5.8.0.1\",\"id\":93,\"name\":\"ERCC_Analysis\",\"features\":[]},\"FilterDuplicates\":{\"userInput\":\"\",\"version\":\"5.8.0.0\",\"id\":85,\"name\":\"FilterDuplicates\",\"features\":[]},\"FileExporter\":{\"userInput\":\"\",\"version\":\"5.8.0.2\",\"id\":90,\"name\":\"FileExporter\",\"features\":[]},\"FieldSupport\":{\"userInput\":\"\",\"version\":\"5.8.0.1\",\"id\":81,\"name\":\"FieldSupport\",\"features\":[]},\"ampliSeqRNA\":{\"userInput\":\"\",\"version\":\"5.8.0.3\",\"id\":87,\"name\":\"ampliSeqRNA\",\"features\":[]},\"sampleID\":{\"userInput\":\"\",\"version\":\"5.8.0.1\",\"id\":91,\"name\":\"sampleID\",\"features\":[]},\"coverageAnalysis\":{\"userInput\":\"\",\"version\":\"5.8.0.8\",\"id\":89,\"name\":\"coverageAnalysis\",\"features\":[]},\"AssemblerSPAdes\":{\"userInput\":\"\",\"version\":\"5.8.0.0\",\"id\":82,\"name\":\"AssemblerSPAdes\",\"features\":[]},\"immuneResponseRNA\":{\"userInput\":\"\",\"version\":\"5.8.0.1\",\"id\":86,\"name\":\"immuneResponseRNA\",\"features\":[]},\"PGxAnalysis\":{\"userInput\":\"\",\"version\":\"5.8.0.1\",\"id\":84,\"name\":\"PGxAnalysis\",\"features\":[]},\"RunTransfer\":{\"userInput\":\"\",\"version\":\"5.8.0.3\",\"id\":83,\"name\":\"RunTransfer\",\"features\":[]},\"variantCaller\":{\"userInput\":\"\",\"version\":\"5.8.0.19\",\"id\":88,\"name\":\"variantCaller\",\"features\":[]},\"RNASeqAnalysis\":{\"userInput\":\"\",\"version\":\"5.4.0.1\",\"id\":56,\"name\":\"RNASeqAnalysis\",\"features\":[]}}", 
			#    "experiment": 247, 
			#    "barcodeKitName": "IonXpress", 
			#    "beadfindargs": "justBeadFind --args-json /opt/ion/config/args_316v2_beadfind.json", 
			#    "threePrimeAdapter": "ATCACCGACTGCCCATAGAGAGGCTGAGAC", 
			#    "thumbnailbasecallerargs": "", 
			#    "status": "run", 
			#    "prebasecallerargs": "BaseCaller --barcode-filter 0.01 --barcode-filter-minreads 20", 
			#    "thumbnailionstatsargs": "", 
			#    "prethumbnailbasecallerargs": "", 
			#    "alignmentargs": "tmap mapall ... stage1 map4", 
			#    "isDuplicateReads": false, 
			#    "libraryKey": "TCAG", 
			#    "date": "2018-04-24T10:29:38.841Z", 
			#    "libraryKitBarcode": null, 
			#    "thumbnailbeadfindargs": "", 
			#    "calibrateargs": "Calibration", 
			#    "tfKey": "ATCG", 
			#    "libraryKitName": "Ion AmpliSeq 2.0 Library Kit", 
			#    "sseBedFile": "", 
			#    "basecallerargs": "BaseCaller --barcode-filter 0.01 --barcode-filter-minreads 20 --phred-table-file /opt/ion/config/phredTable.316v2.B5.h5", 
			#    "base_recalibration_mode": "standard_recal"
			#  }
			#},
		$expanaset -> {'fields'} -> {'barcodedSamples'}=FixJsonDecode($expanaset -> {'fields'} -> {'barcodedSamples'});
		#die "Cannot find variable".Dumper($sampleObj -> {'meta'} -> {'sampleDisplayedName'},$expanaset -> {'fields'} -> {'barcodedSamples'});		
		$sampleObj -> {'data'} -> {'barcodes'} = (join(';',@{$expanaset -> {'fields'} -> {'barcodedSamples'}->{$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodes'}})) or die "Cannot find variable".Dumper($sampleObj -> {'meta'} -> {'sampleDisplayedName'},$expanaset -> {'fields'} -> {'barcodedSamples'})." ";

		my @targetRegionBedFiles;
		my @nucleotideTypes;
		for my $barcode (@{$expanaset -> {'fields'} -> {'barcodedSamples'}->{$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodes'}}){
			#warn Dumper($expanaset -> {'fields'} -> {'barcodedSamples'}->{$sampleObj -> {'meta'} -> {'sampleDisplayedName'}}).$barcode." ".$sampleObj -> {'meta'} -> {'sampleDisplayedName'}." ".$expanaset -> {'fields'} -> {'barcodedSamples'}->{$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$barcode} -> {'nucleotideType'}." ";			
			push @targetRegionBedFiles, $expanaset -> {'fields'} -> {'barcodedSamples'}->{$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$barcode} -> {'targetRegionBedFile'} or die "Cannot find variable";
			push @nucleotideTypes,      $expanaset -> {'fields'} -> {'barcodedSamples'}->{$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$barcode} -> {'nucleotideType'} or die "Cannot find variable";	
		}
		$sampleObj -> 
			{'data'} -> 
				{'targetRegionBedFiles'} = join(';',@targetRegionBedFiles);
		#warn Dumper(\@nucleotideTypes)." "; 	
		$sampleObj -> 
			{'data'} -> 
				{'nucleotideTypes'} = join(';',@nucleotideTypes);

		$sampleObj -> 
			{'data'} -> 
				{'barcodeSequences'} = $sampleObj -> {'data'} -> {'barcodes'};#not present
		$sampleObj -> {'data'} -> {'libraryKitName'} = $expanaset -> {'fields'} -> {'libraryKitName'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'analysisDate'} = $expanaset -> {'fields'} -> {'date'} or die "Cannot find variable";
		
		my $plan = GetSerialObjDb($obj,'rundb.plannedexperiment');
		# A man with a sub plan! A Man, A Plan, A Canal - Panama!
			#		{
			#  "pk": 255, 
			#  "model": "rundb.plannedexperiment", 
			#  "fields": {
			#    "origin": "gui|5.8.0", 
			#    "username": "ionuser", 
			#    "planDisplayedName": "2018-01a", 
			#    "storage_options": "A", 
			#    "planExecutedDate": null, 
			#    "isReverseRun": false, 
			#    "isPlanGroup": false, 
			#    "runMode": "single", 
			#    "templatingKitBarcode": null, 
			#    "sampleTubeLabel": "", 
			#    "preAnalysis": true, 
			#    "isCustom_kitSettings": false, 
			#    "samplePrepKitName": "", 
			#    "reverse_primer": null, 
			#    "applicationGroup": [
			#      "APPLGROUP_0001"
			#    ], 
			#    "seqKitBarcode": null, 
			#    "metaData": "{}", 
			#    "sampleSets": [], 
			#    "isFavorite": false, 
			#    "samplePrepProtocol": null, 
			#    "planStatus": "run", 
			#    "templatingKitName": "Ion PGM Hi-Q View OT2 Kit - 200", 
			#    "runType": "AMPS", 
			#    "latestEAS": 248, 
			#    "projects": [], 
			#    "planPGM": null, 
			#    "planShortID": "S5NRO", 
			#    "isSystemDefault": false, 
			#    "autoName": null, 
			#    "isReusable": false, 
			#    "controlSequencekitname": "", 
			#    "date": "2018-01-30T06:16:00.002Z", 
			#    "isSystem": false, 
			#    "libkit": null, 
			#    "categories": "", 
			#    "planName": "2018-01a", 
			#    "templatingSize": "", 
			#    "parentPlan": null, 
			#    "pairedEndLibraryAdapterName": "", 
			#    "sampleGrouping": [
			#      "SAMPLEGROUP_CV_0006"
			#    ], 
			#    "adapter": null, 
			#    "irworkflow": "", 
			#    "planExecuted": true, 
			#    "usePostBeadfind": true, 
			#    "storageHost": null, 
			#    "expName": "R_2014_01_30_17_18_39_user_PGM-393-2018-01a", 
			#    "libraryReadLength": 0, 
			#    "runname": null, 
			#    "usePreBeadfind": true, 
			#    "planGUID": "4b62eb41-8c73-45cc-827c-75c65b07aa3f", 
			#    "cycles": null
			#  }
		$sampleObj -> {'data'} -> {'projectName'} =  $plan -> {'fields'} -> {'planName'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'templatingKitName'} = $plan -> {'fields'} -> {'templatingKitName'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'planDate'} = $plan -> {'fields'} -> {'date'} or die "Cannot find variable";
		
		$sampleObj -> {'data'} -> {'planExpName'} = $plan -> {'fields'} -> {'expName'} or die "Cannot find variable";
		
		#$sampleObj -> {'data'} -> {'platform'} =  $obj -> {'data'} -> {'exp_json'} -> {'platform'}
		my $exp = GetSerialObjDb($obj,'rundb.experiment');
		$exp -> {'fields'} -> {'log'}=FixJsonDecode($exp -> {'fields'} -> {'log'});
		# again more stuff
			#{
			#  "pk": 247, 
			#  "model": "rundb.experiment", 
			#  "fields": {
			#    "isReverseRun": false, 
			#    "storage_options": "A", 
			#    "chipType": "316v2", 
			#    "user_ack": "U", 
			#    "chefReagentID": "", 
			#    "chefSolutionsPart": "", 
			#    "runMode": "single", 
			#    "chefLotNumber": "", 
			#    "chefChipExpiration1": "", 
			#    "chefChipExpiration2": "", 
			#    "chefExtraInfo_1": "", 
			#    "chefStatus": "", 
			#    "reverse_primer": "Ion Kit", 
			#    "seqKitBarcode": "A30044", 
			#    "chefReagentsPart": "", 
			#    "metaData": "{}", 
			#    "chefInstrumentName": "", 
			#    "chefSolutionsSerialNum": "", 
			#    "log": "{\"num_frames\":73,\"w1ph\":\"10.17\",\"image_map\":\"0 t 1 a 2 c 3 g 4 t 5 a 6 c 7 g 8 t 9 c 10 t 11 g 12 a 13 g 14 c 15 a 16 t 17 c 18 g 19 a 20 t 21 c 22 g 23 a 24 t 25 g 26 t 27 a 28 c 29 a 30 g 31 c\",\"pgmpressure\":\"9.81 - 9.62\",\"harddisk\":\"/dev/sdb, Read:1  UDMA_CRC:1  Multi_Zone:1  Uncorrect:0\",\"fluidic_data_r1\":\"0.345667 0.336000 26.159998 10.370000\",\"planned_run_guid\":\"4b62eb41-8c73-45cc-827c-75c65b07aa3f\",\"seqkitlot\":\"1904842\",\"fpga_version\":81,\"r1ph\":\"6.99\",\"board_serial\":\"002787\",\"chiptargettemperature\":\"49.00\",\"postbeadfind\":\"Yes\",\"graphics_version\":\"36\",\"os_version\":\"21\",\"calibratepassed\":\"Yes\",\"fluidic_data_hschip\":\"0.107167 0.100000 26.239992 6.430000\",\"serial_number\":\"sn274670126\",\"user_name\":\"user\",\"barcodeid\":\"IonXpress\",\"t0_compression\":\"Yes\",\"isreverserun\":\"No\",\"seqkitpart\":\"A30044\",\"pgm_hw\":\"1.1\",\"dac\":[24272,24224,24175,24196,23636,23587,23538,23554],\"start_time\":\"Tue Jul 15 17:18:39 2014\",\"autosettlecalibrate\":\"Yes\",\"fluidic_data_main\":\"0.036667 0.035000 26.380993 4.400000\",\"gain\":\"0.698\",\"seqkitname\":\"IonPGMHiQView\",\"board_version\":null,\"libkit\":\"Ion AmpliSeq 2.0 Library Kit\",\"run_number\":\"393\",\"noise_90pct\":\"3.65\",\"thumbnails\":[],\"autoanalysisname\":\"\",\"user_notes\":\"\",\"origrunseqkitlot\":\"1904842\",\"vrefs\":\"11741 11742\",\"project\":\"\",\"fluidic_data_r2\":\"0.348000 0.336000 26.163998 10.440000\",\"seqkitplanlot\":\"NO_PLAN\",\"w2ph\":\"7.42\",\"end_time\":\"Tue Jul 15 20:20:59 2014\",\"fluidic_data_r4\":\"0.346333 0.336000 26.223995 10.390000\",\"cycles\":15,\"seqkitplanname\":\"IonPGMHiQView\",\"seqkitplanpart\":\"NO_PLAN\",\"planned_run_short_id\":\"S5NRO\",\"advscriptfeatures\":\"0x0\",\"library\":\"hg19\",\"sample\":\"\",\"driver_version\":53,\"frequency\":53333333,\"autoanalyze\":true,\"pgmtemperature\":\"28.41 - 29.33\",\"firmware_version\":134,\"origrunseqkitname\":\"IonPGMHiQView\",\"seqkitdesc\":\"Ion PGM Hi-Q View Sequencing Kit\",\"origrunseqkitpart\":\"A30044\",\"pgm_sw_release\":\"5.6.0\",\"frame_time\":\"0.034145\",\"script_version\":[22,0,0],\"librarykeysequence\":\"TCAG\",\"libbarcode\":\"NOT_SCANNED\",\"cal_chip_high_low_inrange\":[93815,48,6339182],\"liveview_version\":654,\"advanced_user\":\"no\",\"rawtracesok\":\"1\",\"wetload\":\"yes\",\"datacollect_version\":489,\"seqkitplandesc\":\"Ion PGM Hi-Q View Sequencing Kit\",\"fpgatestresult\":\"16726:0  16727:0  16728:0\",\"fluidic_data_w1\":\"0.613667 0.649000 26.119997 18.410000\",\"fluidic_data_w3\":\"0.621667 0.637000 26.119997 18.650000\",\"prerun\":true,\"noise\":\"3.03\",\"blocks\":[],\"cal_chip_hist\":[51,64,11,21,32,43,59,78,98,95,125,246,318,523,946,2508,7559,20882,52501,114549,219547,367267,540339,698240,788772,787961,700107,561813,421499,302842,218429,158581,114792,82743,56933,37512,23830,15076,9933,6825,4817,3480,2470,1858,1281,822,637,557,683,709,102032,0],\"warnings\":\"<Major: Pressure Low @ 16.58>\",\"chipbarcode\":\"AA0422754\",\"flows\":500,\"fluidic_data_r3\":\"0.346667 0.336000 26.191996 10.400000\",\"ref_electrode\":\"0.712999999999999967137 V\",\"analyzeearly\":true,\"oversample\":2,\"runtype\":\"AMPS\",\"experiment_name\":\"R_2014_07_15_17_18_39_user_PGM-393-2018-01a\",\"kernel_build\":\"#50 PREEMPT Fri Nov 5 10:13:40 EDT 2010\",\"fluidic_data_chip\":\"0.026083 0.025000 26.486998 6.260000\",\"chiptype\":\"316v2\",\"tslink_version\":\"1.0.4\",\"r4ph\":\"7.04\",\"chiptemperature\":\"48.97 - 48.97\",\"r3ph\":\"7.00\",\"waste_flow_t0\":\"24.1\",\"origrunseqkitdesc\":\"Ion PGM Hi-Q View Sequencing Kit\",\"r2ph\":\"7.04\"}", 
			#    "plan": 255, 
			#    "chefLogPath": null, 
			#    "chefFlexibleWorkflow": "", 
			#    "platform": "PGM", 
			#    "chefScriptVersion": "", 
			#    "chefOperationMode": "", 
			#    "chefManufactureDate": "", 
			#    "chefSamplePos": "", 
			#    "pinnedRepResult": false, 
			#    "chefReagentsExpiration": "", 
			#    "chefSolutionsLot": "", 
			#    "reagentBarcode": "", 
			#    "chefProgress": 0, 
			#    "chefKitType": "", 
			#    "star": false, 
			#    "chefPackageVer": "", 
			#    "expCompInfo": "", 
			#    "resultDate": "2018-01-30T09:53:54.490Z", 
			#    "flows": 500, 
			#    "chefProtocolDeviationName": null, 
			#    "chefTipRackBarcode": "", 
			#    "chefRemainingSeconds": null, 
			#    "rawdatastyle": "single", 
			#    "chefEndTime": null, 
			#    "date": "2014-07-15T15:18:39Z", 
			#    "diskusage": 136022, 
			#    "chefExtraInfo_2": "", 
			#    "unique": "/results/PGM1/R_2014_07_15_17_18_39_user_PGM-393-2018-01a", 
			#    "expDir": "/results/PGM1/R_2014_07_15_17_18_39_user_PGM-393-2018-01a", 
			#    "chefStartTime": null, 
			#    "autoAnalyze": true, 
			#    "ftpStatus": "Complete", 
			#    "flowsInOrder": "TACGTACGTCTGAGCATCGATCGATGTACAGC", 
			#    "baselineRun": false, 
			#    "displayName": "user PGM-393-2018-01a", 
			#    "chefMessage": "", 
			#    "chefLastUpdate": null, 
			#    "notes": "", 
			#    "sequencekitname": "IonPGMHiQView", 
			#    "chipBarcode": "AA0422754", 
			#    "pgmName": "PGM1", 
			#    "repResult": 122, 
			#    "chefSolutionsExpiration": "", 
			#    "chefReagentsLot": "", 
			#    "storageHost": "localhost", 
			#    "expName": "R_2014_07_15_17_18_39_user_PGM-393-2018-01a", 
			#    "status": "run", 
			#    "chefReagentsSerialNum": "", 
			#    "usePreBeadfind": false, 
			#    "chefChipType2": "", 
			#    "chefChipType1": "", 
			#    "cycles": 15, 
			#    "sequencekitbarcode": "A30044"
			#  }
			#},
		$sampleObj -> {'data'} -> {'platform'} = $exp -> {'fields'} -> {'pgmName'} or die "Cannot find variable";
		#die Dumper($exp -> {'fields'} -> {'log'})." ";
		$sampleObj -> {'data'} -> {'barcodeId'} = $exp -> {'fields'} -> {'log'} -> {'barcodeid'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'sequencekitname'} = $exp -> {'fields'} -> {'sequencekitname'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'chipBarcode'} = $exp -> {'fields'} -> {'log'} -> {'chipbarcode'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'runNumber'} = $exp -> {'fields'} -> {'log'} -> {'run_number'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'libkit'} = $exp -> {'fields'} -> {'log'} -> {'libkit'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'runDate'} = $exp -> {'fields'} -> {'date'} or die "Cannot find variable";

		push(@{$csvNew},\%{$sampleObj});
		
	}
	#$csvNew -> [2] -> {'data'} -> {'Foo'} ++;
	#die "Header". Dumper($foo);
	#die Dumper($csv,$csvNew)." ";
	return $csvNew;
}

sub SetSampleMetaCsv {
	my ($obj,$csv)  = @_;
	for my $sample (GetObjSampleNames($obj)){
		my $dispname = GetObjDispName($obj,$sample);
		push(@{$csv},{'meta' => {'sample' => $sample, 'file' => GetObjFile($obj),'sampleDisplayedName' => $dispname}});
	}
	return $csv;
}

sub SetSampleInfoCsv {
	my ($obj,$csv) = @_;
	my $csvNew;
	for my $sampleObj (@{$csv}){
		#warn Dumper($sampleObj)." ";
		$obj -> {'data'} -> {'exp_json'}=FixJsonDecode($obj -> {'data'} -> {'exp_json'});
		#experimentAnalysisSettings barcodedSamples barcodeSamples
		$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'}=FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'});
		$obj -> {'data'} -> {'barcodeSamples'} = FixJsonDecode($obj -> {'data'} -> {'barcodeSamples'}) if(defined($obj -> {'data'} -> {'barcodeSamples'}));
		$obj -> {'data'} -> {'exp_json'} -> {'log'} =FixJsonDecode($obj -> {'data'} -> {'exp_json'} -> {'log'});
		#warn "Using sample" . Dumper($sampleObj);
		#push(@{$csv},{'meta' => {'sample' => $sample, 'file' => GetObjFile($obj)}});
		$obj -> {'data'} -> {'sampleInfo'}=FixJsonDecode($obj -> {'data'} -> {'sampleInfo'});
		if(not(defined($obj -> {'data'} -> {'sampleInfo'} -> { $sampleObj -> {'meta'} -> {'sample'} }))){
			#die "Missing SampleInfo ".Dumper($obj -> {'data'} -> {'sampleInfo'})." ";
			$sampleObj -> {'data'} -> {'sampleName'} =$obj -> {'data'} -> {'barcodeSamples'} -> { $sampleObj -> {'meta'} -> {'sample'} } or die "Error no such sample".Dumper($obj)." ";
			#get stuff from different place
		}else{
			#die "Missing SampleInfo ".Dumper($obj -> {'data'} -> {'sampleInfo'})." ";
			$sampleObj -> {'data'} -> {'sampleName'} =  $sampleObj -> {'meta'} -> {'sample'} or die "Cannot find variable sample".Dumper($obj -> {'data'} -> {'sampleInfo'} -> { $sampleObj -> {'meta'} -> {'sample'} })." ".Dumper($obj)." ";
		}
		if(not(defined($obj -> {'data'} -> {'project'}))){
			die "Cannot find variable \$obj -> {'data'} -> {'project'} \n".Dumper($obj)." ";
		}else {
			$sampleObj -> {'data'} -> {'projectName'} =  $obj -> {'data'} -> {'project'};
		}
		#$sampleObj -> {'data'} -> {'projectName'} =  $obj -> {'data'} -> {'project'} or die "Cannot find variable".Dumper($obj)." ";
		$sampleObj -> {'data'} -> {'planName'} =  $obj -> {'data'} -> {'plan'} -> {'planName'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'templatingKitName'} =  $obj -> {'data'} -> {'plan'} -> {'templatingKitName'} or die "Cannot find variable";		
		#$sampleObj -> {'data'} -> {'planId'} =  $obj -> {'data'} -> {'plan'} -> {'id'} or warn "Cannot find PlanID variable".Dumper($obj -> {'data'} -> {'plan'});
		$sampleObj -> {'data'} -> {'planDate'} =  $obj -> {'data'} -> {'plan'} -> {'date'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'planExpName'} =  $obj -> {'data'} -> {'plan'} -> {'expName'} or die "Cannot find variable";
		defined($obj -> {'data'} -> {'barcodeId'}) or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'barcodeId'} =  $obj -> {'data'} -> {'barcodeId'};
		
		$obj -> {'data'} -> {'exp_json'}=FixJsonDecode($obj -> {'data'} -> {'exp_json'});
		if(defined($obj -> {'data'} -> {'exp_json'} -> {'platform'})){
			$sampleObj -> {'data'} -> {'platform'} =  $obj -> {'data'} -> {'exp_json'} -> {'platform'}
		}else{
			
			die "Cannot find platform".Dumper($obj)." "if(not(defined($obj -> {'data'} -> {'pgmName'} )));
			$sampleObj -> {'data'} -> {'platform'} = $obj -> {'data'} -> {'pgmName'};
			$sampleObj -> {'data'} -> {'platform'} =~ s/\d*$//g or die "Cleanup error on platform."; 
		}
		defined($obj -> {'data'} -> {'exp_json'} -> {'sequencekitname'})  or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'sequencekitname'} =  $obj -> {'data'} -> {'exp_json'} -> {'sequencekitname'};
		defined( $obj -> {'data'} -> {'exp_json'} -> {'chipBarcode'}) or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'chipBarcode'} =  $obj -> {'data'} -> {'exp_json'} -> {'chipBarcode'};
		$sampleObj -> {'data'} -> {'runDate'} =  $obj -> {'data'} -> {'exp_json'} -> {'date'} or die "Cannot find variable";
		$obj -> {'data'} -> {'exp_json'} -> {'log'}=FixJsonDecode($obj -> {'data'} -> {'exp_json'} -> {'log'});
		$sampleObj -> {'data'} -> {'runNumber'} =  $obj -> {'data'} -> {'exp_json'} -> {'log'} -> {'run_number'} or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'libkit'} =  $obj -> {'data'} -> {'exp_json'} -> {'log'} -> {'libkit'} or die "Cannot find variable";
		
		$obj -> {'data'} -> {'experimentAnalysisSettings'}=FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'});
		
		defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'libraryKitName'}) or die "Cannot find variable";
		$sampleObj -> {'data'} -> {'libraryKitName'} =  $obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'libraryKitName'};
		$sampleObj -> {'data'} -> {'analysisDate'} = $obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'date'} or die "Cannot find variable";
		
		$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'}=FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'});
		#warn Dumper($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'});
		if(not(defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}}))){
			#assume no barcode info; 			
			#die "Ref error ".Dumper($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'targetRegionBedFile'},$csv,$sampleObj -> {'meta'})." ";
			$sampleObj -> 
				{'data'} -> 
					{'targetRegionBedFiles'} = $obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'targetRegionBedFile'};
			$sampleObj -> 
				{'data'} -> 
					{'nucleotideTypes'} = "";
			$sampleObj -> 
				{'data'} -> 
					{'barcodeSequences'} = "";
			
			$sampleObj -> {'data'} -> {'barcodes'} = "";
		
		}else{
			#has barcode info

			$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} =FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}})if(defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}}));
			$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodes'} = FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodes'})if(defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodes'}));
			$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'}=FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'}) if(defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'}));
	
			$sampleObj -> {'data'} -> {'barcodes'} =  join(';',@{$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodes'}});#or die "Cannot find variable";
			#die Dumper($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sample'}} -> {'barcodeSampleInfo'},$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sample'}} -> {'barcodeSampleInfo'} -> {[split(';',$sampleObj -> {'data'} -> {'barcodes'})]});#
			$sampleObj -> 
				{'data'} -> 
					{'targetRegionBedFiles'} = join(';',
						map{if(defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$_} -> {'targetRegionBedFile'})){$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$_} -> {'targetRegionBedFile'} }else{ $obj -> {'data'} -> {'experimentAnalysisSettings'}->{'targetRegionBedFile'} or warn "missing reference on $. "} }(
							split(';',$sampleObj -> {'data'} -> {'barcodes'})));# or die "Cannot find variable".Dumper(split(';',$sampleObj -> {'data'} -> {'barcodes'}),$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'})." ";
			$sampleObj -> 
				{'data'} -> 
					{'nucleotideTypes'} = join(';',
						map{if(defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$_} -> {'nucleotideType'}) && ($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$_} -> {'nucleotideType'} ne "")){$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} -> {$sampleObj -> {'meta'} -> {'sampleDisplayedName'}} -> {'barcodeSampleInfo'} -> {$_} -> {'nucleotideType'} }else{"NA"}}(
							split(';',$sampleObj -> {'data'} -> {'barcodes'}))) or die "Cannot find variable".Dumper($obj)." ";
			$sampleObj -> 
				{'data'} -> 
					{'barcodeSequences'} = join(';',
						map{if(defined($obj -> {'data'} -> {'barcodeInfo'} -> {$_} -> {'sequence'})){$obj -> {'data'} -> {'barcodeInfo'} -> {$_} -> {'sequence'}}else{"NA"} }(
							split(';',$sampleObj -> {'data'} -> {'barcodes'}))) or die "Cannot find variable";
		}


		#die Dumper($sampleObj -> {'data'});

		

		push(@{$csvNew},\%{$sampleObj});
		
	}
	#$csvNew -> [2] -> {'data'} -> {'Foo'} ++;
	#die "Header". Dumper($foo);
	#die Dumper($csv,$csvNew)." ";
	return $csvNew;
}

sub CsvAsString{
	my $csv = shift(@_) or die "Invalid csv".Dumper(@_)." ";
	my $string;
		
	my $header;
	#warn (Dumper($csv));
	for ( 0 .. (scalar(@{$csv}) -1) ){
		for (keys(%{$csv -> [$_] -> {'data'}})){
			$header -> {$_} ++;
		}
	}
	$string .=join(",",sort(keys(%{$header})))."\n";
	for my $record (@{$csv}){
		$string .=join(',',map{$record -> {'data'} -> {$_}}(sort(keys(%{$header}))))."\n";
		#die Dumper(\$string);
	}
	
	return $string;
}
#experimentAnalysisSettings -> libraryKitName/#
#				-> barcodedSamples -> {$sampleObj -> {'meta'} -> {'sample'}} -> barcodes#
#				->  barcodedSamples -> {$sampleObj -> {'meta'} -> {'sample'}} -> barcodeSampleInfo -> @{barcodes} -> targetRegionBedFile
#resultsName
#barcodeInfo -> @{barcodes} -> sequence

sub GetObjFormat {
	my $obj = shift @_ or die Dumper(@_)." ";
	return $obj -> {'meta'} -> {'fileformat'};
}
sub GetObjSampleNames {
	my $obj=shift(@_);
	warn Dumper($obj -> {'data'})." " if(defined($obj -> {'data'}));
	
	$obj -> {'data'} -> {'barcodeSamples'} = FixJsonDecode($obj -> {'data'} -> {'barcodeSamples'})if(defined($obj -> {'data'} -> {'barcodeSamples'}));;
	$obj -> {'data'} -> {'sampleInfo'}=FixJsonDecode($obj -> {'data'} -> {'sampleInfo'}) if(defined($obj -> {'data'} -> {'sampleInfo'}));
	$obj -> {'data'} -> {'experimentAnalysisSettings'}=FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'}) if(defined($obj -> {'data'} -> {'experimentAnalysisSettings'}));
	$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'}=FixJsonDecode($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'}) if(defined($obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'}));
	#warn Dumper($obj).keys(%{$obj -> {'data'} -> {'barcodeSamples'} }).[$obj -> {'data'} -> {'sampleName'}].keys(%{$obj -> {'data'} -> {'sampleInfo'} })." ";	
	if(scalar(keys(%{$obj -> {'data'} -> {'sampleInfo'} }))){
		return keys(%{$obj -> {'data'} -> {'sampleInfo'} });
	}elsif(scalar(keys(%{$obj -> {'data'} -> {'barcodeSamples'} }))){
		return (keys(%{$obj -> {'data'} -> {'barcodeSamples'} }));
	}elsif(scalar(keys(%{$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} }))){
		return (keys(%{$obj -> {'data'} -> {'experimentAnalysisSettings'} -> {'barcodedSamples'} }));
	}elsif(scalar([$obj -> {'data'} -> {'sampleName'}])){
		return ([$obj -> {'data'} -> {'sampleName'}]);
	}else{
		die "couldn't find sampleinfo".Dumper($obj)." ";
	}

	#try other location with sampleinformation
}
	
sub GetObjDispName {
	my $obj=shift(@_);
	my $name= shift(@_);
	return $obj -> {'data'} -> {'sampleInfo'} -> {$name} -> {'displayedName'} if(defined($obj -> {'data'} -> {'sampleInfo'} -> {$name} -> {'displayedName'}));
	warn "Warning no displayedname found using defult name.";
	return $name ;
}

sub GetObjFile {
	my $obj=shift(@_);
	my $ret = $obj -> {'meta'} -> {'file'} or die Dumper($obj);
	return ($ret);
}
