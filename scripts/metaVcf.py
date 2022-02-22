#!/usr/bin/env python
import argparse
import vcf

def main():
	parser = argparse.ArgumentParser(prog='myprogram',description='Prefix your vcf annotations with a caller prefix so that "DP" for example will also be present as "caller.DP"',)
	parser.add_argument('caller', help='caller for prefixing the annotations')
	parser.add_argument('vcfopen', type=open, help='Input vcf for adding the caller prefixed annotations')
	
	args = parser.parse_args()
	
	print vars(args)
	
	vcf_reader = vcf.Reader( args.vcfopen )
	
	print vars(vcf)
	print
	print
	print vars(vcf_reader)
	print 
	
	#parse examples
	##FORMAT=<ID=RO,Number=1,Type=Integer,Description="Reference allele observation count">
	##INFO=<ID=AB,Number=A,Type=Float,Description="Allele balance at heterozygous sites: a number between 0 and 1 representing the ratio of reads showing the reference allele to all reads, considering only reads from individuals called as heterozygous">
	
	for hline in vcf_reader._header_lines: 
		print hline
		def calleriseHeaderField (hline, caller):
			hlinesplit=hline.split('=')
	                infotag=hlinesplit[2].split(',')
	                infotag[0]= caller + infotag[0]
	                print infotag
	                hlinesplit[2]=','.join(infotag)
	                hline='='.join(hlinesplit)
	                return hline
		
		if(hline[0:6] == '##INFO' or hline[0:8] == '##FORMAT'):
			print calleriseHeaderField(hline, args.caller)
		print hline

	for vcrecord in vcf_reader:
		print vars(vcrecord)
		def stringify(val, none='.', delim=','):
			if type(val) == type([]):
				return delim.join(_map(str, val, none))
			if val is not None:
				return val
			else:
				return none
		
		def format_alt(alt):
			print alt
			return ','.join(_map(str, alt))

		def format_filter(flt):
			if flt == []:
				return 'PASS'
			return stringify(flt, none='.', delim=';')
		#def format_info(vcf_reader, info):
		#	if not info:
		#		return '.'
		#	return ';'.join(.stringify_pair(f, info[f]) for f in info.keys().sort()
		#	#Here to get it to work!!!!!
		def format_info(info):
			if not info:
				return '.'
			return ';'.join(stringify_pair(f, info[f]) for f in sorted(info.keys()) )

		def format_sample(fmt, sample):
			if hasattr(sample.data, 'GT'):
				if sample.data.GT == '.':
					gt = './.'
					#sample.data._fields = ""	
				else: 
					gt = sample.data.GT
			else:
				gt = './.' if 'GT' in fmt else ''
			result = [gt] if gt else []
			# Following the VCF spec, GT is always the first item whenever it is present.
			if sample.data.GT != '.':
				for field in sample.data._fields:
					value = getattr(sample.data,field)
					if field == 'GT':
						continue
					#if field == 'FT':
					#	result.append(format_filter(value))
					else:
						result.append(stringify(value))
			return ':'.join(str(x) for x in result)
		def stringify_pair(x, y, none='.', delim=','):
			if isinstance(y, bool):
				return str(x) if y else ""
			return "%s=%s" % (str(x), stringify(y, none=none, delim=delim))
		
		
		def asvcf_record(record):
			""" write a record to the file """
			tojoin=[record.CHROM, record.POS, record.ID, record.REF, format_alt( record.ALT), record.QUAL or '.', format_filter(record.FILTER),
                                format_info(record.INFO)]
			ffs = "\t".join(str(x) for x in tojoin);
			if record.FORMAT:
				ffs +="\t" + record.FORMAT
			samples = [format_sample(record.FORMAT, sample)
				for sample in record.samples]
			return '\t'.join([ffs] + samples)
				
		def _map(func, iterable, none='.'):
			'''``map``, but make None values none.'''
			return [func(x) if x is not None else none
				for x in iterable]
		
		def calleriseInfo(caller,record):
			for infokey in sorted(record.INFO.keys()):
				record.INFO[caller + infokey] = record.INFO[infokey]
		def calleriseSampleFormat(caller,record):
			formatfields = record.FORMAT.split(':')
			callerisedFormatFields=[]
			for field in formatfields:
				callerisedFormatFields.append(caller + field)
			record.FORMAT = ":".join( formatfields + callerisedFormatFields)
			record.samplesAddFormat = []
			sample_data = {}
			for sample in record.samples:
				sample_data["name"]  = sample.data
				for field in sample.data._fields:
                                        value = getattr(sample.data,field)
                                        sample_data[ sample_data["name"] ][caller + field] = value

		calleriseInfo(args.caller,vcrecord)
		calleriseSampleFormat(args.caller,vcrecord)
		print  asvcf_record(vcrecord)
		exit(1)

main()
