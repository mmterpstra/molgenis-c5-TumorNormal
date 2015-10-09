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


![Workflow](https://cdn.rawgit.com/mmterpstra/molgenis-c5-TumorNormal/devel/img/TumorNormalMin.svg)

goals:
  - is buildable with easybuild?
  - works on new slurm cluster
  - integrate tumor-normal callers

