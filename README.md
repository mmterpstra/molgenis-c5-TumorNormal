# molgenis-c5-TumorNormal
The main goal is to detect variants in tumor-normal sample combinations.

references will follow:

| Name         | project website                                                                            | Article          |
| ------------ | ------------------------------------------------------------------------------------------ | ---------------- |
| Fastqc       | [bioinformatics.babraham.ac.uk](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) | |
| bwa          | [github](https://github.com/lh3/bwa)                                                       | [preprint](http://arxiv.org/abs/1303.3997) |
| picard-tools | [sourceforge](http://picard.sourceforge.net/)                                              | [instructions below faq](http://picard.sourceforge.net/) |
| GATK toolkit | [project home](http://www.broadinstitute.org/gatk/)                                        | [instructions here](https://www.broadinstitute.org/gatk/about/citing-gatk) |
| VarScan      | [github](http://dkoboldt.github.io/varscan/)                                               | [pubmed link](http://www.ncbi.nlm.nih.gov/pubmed/22300766) |
| SnpEff       | [sourceforge](http://snpeff.sourceforge.net/index.html)                                    |[pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22728672)|
| SnpSift      | [sourceforge](http://snpeff.sourceforge.net/index.html)                                    |[pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22435069)|
| samtools     | [project home](http://www.htslib.org/)                                                     |[pubmed](http://www.ncbi.nlm.nih.gov/pubmed/19505943)|
| Compute      | [project home](http://www.molgenis.org/wiki/ComputeStart)                                  |[citeseerx](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.415.9799)|
| DNAcopy      | [bioconductor.org](http://www.bioconductor.org/packages/release/bioc/html/DNAcopy.html)    |[bioconductor.org](http://www.bioconductor.org/packages/release/bioc/vignettes/DNAcopy/inst/doc/DNAcopy.pdf)|
| Cosmic       | [project home](http://cancer.sanger.ac.uk/cosmic)                                          |[pubmed](http://www.ncbi.nlm.nih.gov/pubmed/25355519) |
| 1000g        | [project home](http://www.1000genomes.org/)                                                |[pubmed](http://www.ncbi.nlm.nih.gov/pubmed/23128226)|
| dbsnp        | [project home](http://www.ncbi.nlm.nih.gov/snp/)                                           |[pubmed](http://www.ncbi.nlm.nih.gov/pubmed/11125122)|
| dbnsfp       | [project home](https://sites.google.com/site/jpopgen/dbNSFP)                               |[site](https://sites.google.com/site/jpopgen/dbNSFP) [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/21520341), [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/23843252) and [drive link](https://drive.google.com/file/d/0BwXtJxmTWY_td2ZoTXRCQTAySm8/view?usp=sharing)|


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

See picture below:

![Workflow](https://cdn.rawgit.com/mmterpstra/molgenis-c5-TumorNormal/devel/img/TumorNormalMin.svg)

Variantcalling
==============
This is done with the haplotype caller using `-stand_call_conf 10.0` and `-stand_emit_conf 20.0` (produce calls with qual >=10 and mark them with lowQual if <20 ).

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


goals:
  - is buildable with easybuild?
  - works on new slurm cluster
  - integrate tumor-normal callers

