# molgenis-c5-TumorNormal
The main goal is to detect variants in tumor-normal sample combinations.

Build status
------------

branches

 - master ![alt master](https://travis-ci.org/mmterpstra/molgenis-c5-TumorNormal.svg?branch=master)
 - devel ![alt devel](https://travis-ci.org/mmterpstra/molgenis-c5-TumorNormal.svg?branch=devel)

Install
-----------

check out my `.travis.yml` and the `test/*.sh` files.

Prerequirements:
 - Lmod
 - EasyBuild
 - Molgenis-Compute
 - All the other software: installs using Easybuild.
 - Slurm sheduler or large enough machine to run locally perferably ~30g mem & ~1t storage and 8 cpu's

Running
------- 

Prepare a samplesheet similar to `Samplesheet.csv` update the setting to match your dataset and run it using:

```
bash GenerateScripts2.sh [none|exome|rna|nugene|nugrna|iont|withpoly] samplesheet projectname targetsList

[none|exome|rna|nugene|nugrna|iont|withpoly]
	workflow selection
samplesheet
	Samplesheet describing your data
projectname
	Project name. Will generate the data below /path/to/projects/${project} and some main project files are using this variable.
targetsList
	interval_list file to limit/split your datasets.
``` 

Methods
------------

Variant Calling
===============

The variant calling pipeline is an implementation of a variant calling pipeline using the GATK tools and molgenis compute as workflow management software. As variant caller this pipeline uses the `HaplotypeCaller` instead of `Mutect` this because the sensitivity of `Mutect` needs multiple normal samples to correct for the senstivity if the caller.
Alignment of reads was done using BWA [cite](http://arxiv.org/abs/1303.3997) and the Genome Analysis Toolkit (GATK) [cite](https://www.broadinstitute.org/gatk/about/citing-gatk).
Using the GRCH37 decoy build from the GATK bundle. Picard Tools was used for format conversion and Marking duplicates. Annotation of the variants was done using 
SnpEff [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22728672) / SnpSift [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22435069) with the ensembl release 75 gene annotations and the dbNSFP2.7 database ,
the GATK was used with variant annotations of dbsnp 138, Cosmic v72, 1000 genomes phase 3 and Exac 0.3 databases. The data was filtered for quality metrics according to GATK recommendations (described below) and custom filters for population frequency and variant effect. 

Cnv Analysis
============

Copy number variation data were generated using Samtools and Varscan (Li et al., 2009, Koboldt et al., 2012) ([pubmed](http://www.ncbi.nlm.nih.gov/pubmed/19505943), [pubmed link](http://www.ncbi.nlm.nih.gov/pubmed/22300766)).
The GC-content normalised log2 fold change data was generated using using data of the tumor sample and the matched normal sample. Using a minimal segment size of 2000 bp, a maximal segment size 
of 5000 bp, minimal base wise coverage of 1 and the alignments with a mapping quality greater than 40 to calculate the fold changes, otherwise the default settings are assumed. The segment calling was done with DNAcopy algoritmn 
(Olshen et al., 2004). In addition to the default settings the circulair binary segmentation (CBS) calls were merged if they had an SD of < 0.5 with adjacent segments and weigths were added based on 
```weigth = mean(normal/sample)+delta(normal,sample)```. Where ```normal``` = mean coverage per base in normal control and ```sample``` = mean coverage per base in described sample. 
The results were plotted using R after using perl for format conversion.

Alternate Workflows
==================

These are the atlternate workflows and the change compared to the original.
 - Nugene
    - In the nugene analysis the BQSR step is omitted because this is only meant for enritchment capturing a whole exome/genome. Using this on a small capturing kit might result in missing variant calls because
 of lack of observations. This happens because for BSQR you'll need approx 100*10^6 basepairs for recalibration. 
    - Also Landing probe removal by aligment location was performed with custom script from pipeline-util repo and quality trimming (Q>20) with bbduk was performed
 - NugeneInc
    - This is not the official nugene pipeline but modeled to look like it: trimming for landing probe sequence and quality >20 trim using bbduk from the bbmap package.
 - RNAseq
    - This has Hisat2 as aligner, used the GATK tool SplitNReads and uses different haplotypecaller settings.
 - Exome
    - This is considered the default.
 - NugeneRNA 
   - combination of the Nugene and the RNAseq protocol changes.
 - none
    - WGS protocol (future work).
 - Iontorrent
    - Ion torrent workflow.... similar to nugene although work in progress.
 - With non polymorfic reads
    - Does not filter for non polymorfic reads.



References
==========

| Name         | project website                                                                            | Article          |
| ------------ | ------------------------------------------------------------------------------------------ | ---------------- |
| Fastqc       | [bioinformatics.babraham.ac.uk](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) | |
| BWA          | [github](https://github.com/lh3/bwa)                                                       | [preprint](http://arxiv.org/abs/1303.3997) |
| Picard-tools | [sourceforge](http://picard.sourceforge.net/)                                              | [instructions below faq](http://picard.sourceforge.net/) |
| GATK toolkit | [project home](http://www.broadinstitute.org/gatk/)                                        | [instructions here](https://www.broadinstitute.org/gatk/about/citing-gatk) |
| VarScan      | [github](http://dkoboldt.github.io/varscan/)                                               | [pubmed link](http://www.ncbi.nlm.nih.gov/pubmed/22300766) |
| SnpEff       | [sourceforge](http://snpeff.sourceforge.net/index.html)                                    | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22728672)|
| SnpSift      | [sourceforge](http://snpeff.sourceforge.net/index.html)                                    | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22435069)|
| SAMtools     | [project home](http://www.htslib.org/)                                                     | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/19505943)|
| Compute      | [project home](http://www.molgenis.org/wiki/ComputeStart)                                  | [citeseerx](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.415.9799)|
| DNAcopy      | [bioconductor.org](http://www.bioconductor.org/packages/release/bioc/html/DNAcopy.html)    | [bioconductor.org](http://www.bioconductor.org/packages/release/bioc/vignettes/DNAcopy/inst/doc/DNAcopy.pdf)|
| Cosmic       | [project home](http://cancer.sanger.ac.uk/cosmic)                                          | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/25355519) |
| 1000 genomes | [project home](http://www.1000genomes.org/)                                                | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/23128226)|
| dbSNP        | [project home](http://www.ncbi.nlm.nih.gov/snp/)                                           | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/11125122)|
| dbNSFP       | [project home](https://sites.google.com/site/jpopgen/dbNSFP)                               | [site](https://sites.google.com/site/jpopgen/dbNSFP) [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/21520341), [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/23843252) and [drive link](https://drive.google.com/file/d/0BwXtJxmTWY_td2ZoTXRCQTAySm8/view?usp=sharing)|
| ensembl build 75 | [archive site](http://feb2014.archive.ensembl.org/index.html)			    | [doi.org link](http://dx.doi.org/10.1093/nar/gkt1196)
| Exac         | [project home](http://exac.broadinstitute.org/)                                            | [instructions here](http://exac.broadinstitute.org/about)|
| FusionCatcher | [github](https://github.com/ndaniel/fusioncatcher)					    | [instructions here](https://github.com/ndaniel/fusioncatcher#citing)
| manta		| [github](https://github.com/Illumina/manta)						    | [preprint](http://biorxiv.org/content/early/2015/08/10/024232)
| HTSeq		| [project home](http://www-huber.embl.de/users/anders/HTSeq/doc/index.html)		    | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/25260700)
| BBMap		| [sourceforge](https://sourceforge.net/projects/bbmap/)				    | na |
| BEDTools2	| [github](https://github.com/arq5x/bedtools2)						    | [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/20110278) 
| Hisat2	| [project home](http://ccb.jhu.edu/software/hisat2/index.shtml) [github](https://github.com/infphilo/hisat2/)     | [nature](http://www.nature.com/nprot/journal/v11/n9/full/nprot.2016.095.html)


Versions
========

Version managment done with lmod `lua based implementation of environment modules`. Installation/deployment management done with Easybuild.
Here are the tools and software versions (for the current versions look at the *.siteconfig.csv):

| software              | version |
| --------              | ------- |
| fastQC		 | 0.11.5-Java-1.7.0_80
| BWA		 | 0.7.12-foss-2016a
| picard		 | 1.140-foss-2016a-Java-1.8.0_74
| R		 | 3.2.2-foss-2016a-bioconductor
| GATK 		 | 3.5-foss-2016a-Java-1.7.0_80
| snpEff		 | 4.1g-Java-1.7.0_80
| VarScan		 | 2.4.0-Java-1.7.0_80
| SAMtools	 | 0.1.18-foss-2016a
| VCFtools	 | 0.1.12b-foss-2016a-Perl-5.20.2-bare
| pipeline-util 	 | 0.4.1-foss-2016a-Perl-5.20.2-bare
| TableToXlsx | latest 
| DigitalBarcodeReadgroups | 0.1.4-foss-2016a-Perl-5.20.2-bare
| BBMap		 | 35.69-Java-1.7.0_80
| BEDTools	 | 2.25.0-foss-2016a
| hisat2		 | 2.0.3-beta-foss-2016a
| HTSeq		 | 0.6.1-p1-goolfc-2.7.11-Python-2.7.9
| FusionCatcher	 | 0.99.6a-foss-2016a-Python-2.7.11
| markdown(R package)	| 0.7.7-foss-2016a-R-3.2.2-bioconductor
| manta		 | 0.29.5-foss-2016a 


Resource links
--------------

The resource links for installing references/preparing them

| name          | site 
| ------------- | ---- 
| GATK Bundle   | [ human reference ](http://gatkforums.broadinstitute.org/discussion/1213/what-s-in-the-resource-bundle-and-how-can-i-get-it)
| Ensembl       | [reference/gtf dowload](http://www.ensembl.org/info/data/ftp/index.html)
| UCSC Tools    | [ format conversion/additional tools ](http://hgdownload.soe.ucsc.edu/admin/exe/)

Workflow
--------

See pictures below for the different sub workflows:

generic workflow:
![Workflow](https://rawgit.com/mmterpstra/molgenis-c5-TumorNormal/devel/img/TumorNormalMin.svg)

nugene workflow:
![Nugene Workflow](https://rawgit.com/mmterpstra/molgenis-c5-TumorNormal/devel/img/TumorNormalMin_nugene.svg)

Output files
------------

The output contains 3 different types:

Project folder
 - All the (intermediate) files of the analysis
 - Use: to clean up
${project}_nobam.zip
 - All the relevant files excluding the bam files.
 - Subfolders
    - `CovariantAnalysis/`
       - The base quality score recalibration results. This shows the effect of the analysis on the quality scores.
    - `fastqc/`
       - The complete results of the fastqc tool 
    - `HsMetrics/`
       - The complete results of the picard CalculateHsMetrics tool. ${sample}.hsmetrics.log: calulated metrics like fraction of bases 20x covered and mean coverage. ${sample}.hsmetrics.pertargetcov.tsv: coverage for each target region 
    - `md/`
       - **Collected metrics** of the more important quality metrics in html/markdown format. 
    - `multipleMetrics/`
       - The complete results of the picard multipleMetrics tool. Many metrics included...
    - `variantfiltering/`
       - The (soft) filtered vcf files, to make IGV(integrative genomics viewer)/bioinformatics people happy.
    - `varscan.${controlSampleName}/`
       - **Our CNV analysis** see the varscan.normals/*.pdf varscan.normals/*.seg files for results. This shows the copynumber ratios versus the normal samples.
    - `xlsx/`
       - **The table dumps of the VCF files made for excel spreadsheet processing**. Tree types are present raw,min and filtered for viewing the raw variant calls (without filtering), the variant calls with a selected amount of columns and the variant calls filtered for population frequency and function. This for different type of calls: single nucletide variants (snv), small indels and multinucleotide polymorfisms (indelmnp) and structural variants called with manta (sv / work in progress).



Variantcalling
==============
This is done with the haplotype caller using `-stand_call_conf 10.0` and `-stand_emit_conf 20.0` (call bases with QUAL > 10). 
Instead of the default calling with a QUAL >= 30 (see also the 'Filtering of variant calls' paragraph).

Filtering of variant calls
==========================
different filtering based on type:
 - snv
 - indel & mnp

| name 		| expression 	| applied on  			| description |
| ---- 		| ---------- 	| ----------- 			| ----------- |
| "LowQual" 	| "QUAL < 30" 	| both (snv and indel & mnp) 	| Filter for the possibility (> 1/1000 or <30 pred scaled) that the variant call is wrong using a bayesian model. |
| "QDlt2"	| "QD < 2.0"	| both 				| Filter for the pred scaled possibility that the variant call is wrong divided by the depth < 2.0 |
| "MQlt40"	| "MQ < 40.0"	| snv				| Filter snv for the pred scaled possibility that a mapping is wrong, capped 60, calculated with secondary hits using the base quality scores at the different positions to call it 0 or higher. Filter for unique mappings. |
| "MQRankSumlt-12_5" | "MQRankSum < -12.5" | snv		| Filter snv for mutations in which the mutation or the reference has difficulties mapping depending on one another. |
| "MQRankSumlt-20" | "MQRankSum < -20" | both                | Filter indel for mutations in which the mutation or the reference has difficulties mapping depending on one another. |
| "ReadPosRankSumlt-20" | "ReadPosRankSum < -20.0"| snv		|	|
| "FSgt60"	| "FS > 60.0"   | snv                           |	|
| "FSgt200"	| "FS > 200.0"   | indel                        |	|
| "RPAgt8" 	| "vc.getAttribute('RPA').0 > 8||vc.getAttribute('RPA').1 > 8||vc.getAttribute('RPA').2 > 8" | both |	|
| "TeMeermanAlleleBiasgt5" | TeMeermanAlleleBias > 5.0 | both	| never filters anything -> legency artifact|
| "NotPolymorfic" | all GT equal | both				|	|
| "NotPutatativeHarmfulVariant" | see descr. | both		| everything that is not fuctional according the [snpeff documentation](http://snpeff.sourceforge.net/SnpEff_manual.html) under 'Effect prediction details' aka: "!((vc.hasAttribute('SNPEFF_IMPACT') && vc.getAttribute('SNPEFF_IMPACT').equals('HIGH'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('NON_SYNONYMOUS_CODING'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_INSERTION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE_PLUS_CODON_INSERTION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_DELETION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE_PLUS_CODON_DELETION')))" |
| "1000gMAFgt0.02" | see descr. | both				| entire 1000g phase 1 alelle fequency of 2% aka "(vc.hasAttribute('1000gPhase1Snps.AF') &&(vc.getAttribute('1000gPhase1Snps.AF') > 0.02&&vc.getAttribute('1000gPhase1Snps.AF') < 0.98))" --filterName "1000gMAFgt0.02" |
| "1000gEURMAFgt0.02" | see descr. | both			| european 1000g phase 1 alelle fequency of 2% aka "(vc.hasAttribute('1000gPhase1Snps.EUR_AF') && (vc.getAttribute('1000gPhase1Snps.EUR_AF') > 0.02&&vc.getAttribute('1000gPhase1Snps.EUR_AF') < 0.98))" --filterName "1000gEURMAFgt0.02" |
| "QDlt2andQdbyAflt8" | "QD < 2.0 && QD / AF < 8.0 | both	| having both QD < 2 and QD/ AF < 8 in tekst:the qual divided by depth less then 2 and the qual divided by depth divided by allele frequency less than 8. The second parameter(QDAF is to avoid removing low AF (read like: rare) variant calls from the data...)  |

Filtering of variant calls V2
==========================

The recommended filtering procedure depends on the sample size, sequencing method, target region size and depth these are general recommendations. The filtering might benefit from less stringent filtering of the variant statistics to increase sensitivity. The refiltering is best done on the raw data because these still contain the removed variance. Also consider adding exac.ac/exac.an <> 0.02 and adding the population(european/asian/american/african) specific filters for exac,esp6500 and 1000g. If you document your filtering I might add it to the filtering pipeline.

Note the different filtering strategies for the following subtypes.
 - snv
 - indel & mnp

| Name          		| Expression    		| Applied on                    | Description |
| ----          		| ----------    		| -----------                   | ----------- |
| "LowQual"     		| "QUAL < 30"   		| both (snv and indel & mnp)    | Variant statistic. Filter for the possibility (> 1/1000 or <30 pred scaled) that the variant call is wrong using a bayesian model. |
| "QDlt2"			| "QD < 2.0"    		| both                          | Variant statistic. Filter for the pred scaled possibility that the variant call is wrong divided by the depth < 2.0 |
| "MQlt40"			| "MQ < 40.0"			| snv				| Variant statistic. Filter snv for the pred scaled possibility that a mapping is wrong, capped 60, calculated with secondary hits using the base quality scores at the different positions to call it 0 or higher. Filter for unique mappings. |
| "MQRankSumlt-12_5"		| "MQRankSum < -12.5" 		| snv				| Variant statistic. Filter snv for mutations in which the mutation or the reference has difficulties mapping depending on one another. |
| "MQRankSumlt-20" 		| "MQRankSum < -20" 		| indel & mnp  			| Variant statistic. Filter indel for mutations in which the mutation or the reference has difficulties mapping depending on one another. |
| "ReadPosRankSumlt-20" 	| "ReadPosRankSum < -20.0"	| snv				| Variant statistic. Fisher strand bias of the covering reads. High values == more bias. |
| "FSgt60"			| "FS > 60.0"			| snv  				| Variant statistic. Fisher strand bias of the covering reads. High values == more bias. |
| "FSgt200"			| "FS > 200.0"			| indel & mnp			| Variant statistic. Tandem repeat annotation of the region. The more repeats the less likely the indel call is true. Sequencing has difficulties with repeats (with about >=8 repeating units).	|
| "RPAgt8" 			| "vc.getAttribute('RPA').0 > 8||vc.getAttribute('RPA').1 > 8||vc.getAttribute('RPA').2 > 8" | both | Functional Annotation. Tandem repeat annotation of the region. The more repeats the less likely the indel call is true. Sequencing has difficulties with repeats (having about >=8 repeating units). |
| "TeMeermanAlleleBiasgt5" 	| TeMeermanAlleleBias > 5.0	| both				| Variant statistic. Never filters anything -> legency artifact|
| "NotPolymorfic" 		| all GT equal			| both				| Genotype annotation. All the genotypes are equal. If analysed with a proper control this variant is very unlikely to be harmful.|
| "NotPutatativeHarmfulVariant" | see descr. 			| both				| Functional annotation. everything that is not fuctional according the [snpeff documentation](http://snpeff.sourceforge.net/SnpEff_manual.html) under 'Effect prediction details' aka: ###Should be updated for the SNPEFFANN FIELDS :"!((vc.hasAttribute('SNPEFFANN_ANNOTATION_IMPACT') && vc.getAttribute('SNPEFFANN_ANNOTATION_IMPACT').equals('HIGH'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('NON_SYNONYMOUS_CODING'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_INSERTION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE_PLUS_CODON_INSERTION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_DELETION'))||(vc.hasAttribute('SNPEFF_EFFECT') && vc.getAttribute('SNPEFF_EFFECT').equals('CODON_CHANGE_PLUS_CODON_DELETION')))" |
| "1000gMAFgt0.02" 		| see descr.			| both				| Population annotation. entire 1000g phase 1 alelle fequency of 2% aka "(vc.hasAttribute('1000gPhase1Snps.AF') &&(vc.getAttribute('1000gPhase1Snps.AF') > 0.02&&vc.getAttribute('1000gPhase1Snps.AF') < 0.98))" --filterName "1000gMAFgt0.02" |
| "1000gEURMAFgt0.02" 		| see descr. 			| both				| Population annotation. european 1000g phase 1 alelle fequency of 2% aka "(vc.hasAttribute('1000gPhase1Snps.EUR_AF') && (vc.getAttribute('1000gPhase1Snps.EUR_AF') > 0.02&&vc.getAttribute('1000gPhase1Snps.EUR_AF') < 0.98))" --filterName "1000gEURMAFgt0.02" |
| "QDlt2andQdbyAflt8" 		| "QD < 2.0 && QD / AF < 8.0	| both				| Variant statistic. having both QD < 2 and QD/ AF < 8 in tekst:the qual divided by depth less then 2 and the qual divided by depth divided by allele frequency less than 8. The second parameter(QDAF is to avoid removing low AF (read like: rare) variant calls from the data...)  |

