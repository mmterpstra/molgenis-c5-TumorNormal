import sys
import subprocess

if len(sys.argv) != 3:
	print("Usage:\t" + sys.argv[0] + "\t<input_sinvict_file_path>\t<output_filename>")
	exit(0)


outfile = open(sys.argv[2], "w")
outfile.write("##fileformat=VCFv4.3\n")
outfile.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")

with open(sys.argv[1]) as infile:
	for line in infile:
		line = line.rstrip()
		tokens = line.split()
		
		chromosome = tokens[0]
		position = tokens[1]
		ref = tokens[3]
		alt = tokens[5]
	if alt[0] == "+" :
		#insertion
		alt = ref + alt[1:]
	if alt[0] == "-" :
	#deletion
		position -= 1
		fa = subprocess.check_output(["samtools", "faidx", "/data/umcg-mterpstra/apps/data/ftp.broadinstitute.org/bundle/2.8/b37/human_g1k_v37_decoy.fasta", chromosome+":"+position+"-"+position])
		base = fa.split("\n")[1]
		base.rstrip()
		ref = base + alt[1:]
		alt = base
	      	
		outfile.write(chromosome + "\t" + position + "\t" +
			"." + "\t" + ref + "\t" + alt + "\t" + "." + "\t" +
			"PASS" + "\t" + "." + "\n")
	

#original copied at 19okt2021 from: https://raw.githubusercontent.com/sfu-compbio/sinvict/master/sinvict_to_vcf.py
