# CconcisusGenomospecies

## Overview
This is a repository of scripts used in the genomic analysis of *Campylobacter concisus* genomospecies GS1 and GS2.  There are three scripts of relevance here:
* `listAandB.pl`
* `table2Dist2Nex.pl`
* `COGnitorParse2full.pl`

## Requirements to run these scripts 

The following software is required to run these scripts.

* Perl -- a relatively recent version of Perl, 5.20 and above.  Packages required are `Getopt::Long` and `DBI` (for connections to MySQL).
* R version 3.5 and above.  This has to be directly accessible from the path. 
* MySQL
* NCBI Blast+.  Executables are accessed via the folder, not necessarilly from the path.
* The COGsoft suite of programs, which have to be compiled locally to work. These are available at [sourceforge.net](https://sourceforge.net/projects/cogtriangles/).  Alternatively the tar file `COGsoft.201204.tar` can be found at the FTP location ftp://ftp.ncbi.nih.gov/pub/wolf/COGs/COGsoft.  Executables are accessed via the software installation folder, not necessarily from the path.  Please note that compilation of these programs is not straightforward, but there are searchable solutions on the Internet to deal with such issues.


## Script description

### listAandB.pl

This is a Perl script that takes a text file (tsv) of BLAST score ratio (BSR) values for CDS identified in the genomes under examination and writes a new text file (tsv) that contains the results where the target genomes (listA) have BSR values that fulfil ConditionA (generally >= 0.8) and the non-target genomes (listB) have BSR values that fulfil ConditionB (generally <=0.4). The aim is to identify genes that have high sequence similarity in the target genomes and low sequence similarity in the non-target genomes.  The following input is required at runtime as options:
* `listA` -- a list of target genomes that fulfil ConditionA
* `listB` -- a list of target genomes that fulfil ConditionB
* `inFile` -- a text file (tsv) of BLAST score ratio (BSR) values for CDS identified in the genomes under examination
* `outFile` -- a test file of results fulfilling both ConditionA and ConditionB

A	running example is:

```perl
./listAandB.pl -listA ArcoCryaerophilusListA -listB ArcoCryaerophilusListB \
-inFile Arco_bsr_matrix_values.txt -outFile test.txt
```


### COGnitorParse2full.pl

A Perl script to take the a set of amino acid fasta files and analyse them with the COG software.  The input here is a list of genomes that have been through annotation with [Prokka](https://github.com/tseemann/prokka), for which the amino acid fasta files -- ```*.faa``` -- are used as input.  The following input is required at runtime as options:
* `inList` -- a list of genomes to be analysed.  This is a tab delimted file with 4 columns: input genome name | genus | species | output genome name.  The input and output genome name can be the same, but do not have to be.
* `dataGroup` -- a folder in which the Prokka annotations can be found, each within their own folder for that isolate.

A	running example is:

```perl
./COGnitorParse2full.pl -inList inList.txt -dataGroup workingGroup
```

The source data is available at the FTP site: ftp://ftp.ncbi.nih.gov/pub/COG/COG2014/data/.  The COG files `cog2003-2014.csv`, `cognames2003-2014.tab`, `fun2003-2014.tab`, `genomes2003-2014.tab` and `prot2003-2014.fa` have to be renamed with a '-' being replaced by an underscore in the names.  It is also necessary to make a BLAST protein database of the renamed `prot2003_2014.fa` file.


### table2Dist2Nex.pl

A Perl script to take in a table from a set of data and make a simple distance matrix from it that can then be viewed in SplitsTree.  The following input is required at runtime as options:
1. `metaFile` -- a metafile of the items under analyses.  A list of the genomes, in the same order they are in the datafiles
2. `metaHeader` -- a declaration of whether the metafile has a header or not - this can be either `true` or `false`
3. `project` -- a project name to find a root folder -- this will have to be adpated to your folder
4. `inFile` -- an input file of data to analyse as a standard table -- the first column can be left in or removed, the code will remove it if necessary
5. `COGdata` -- a description of whether the COG dataset is being used -- values are either `yes` or `no`

A	running example is:

```perl
./table2Dist2Nex.pl -inFile smallInfile -project currentWork -metaFile isolateList \ 
-metaHeader false -COGdata yes
```
