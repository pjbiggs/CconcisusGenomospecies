# CconcisusGenomospecies
A repository of scripts used in the genomic analysis of Campylobacter concisus genomospecies GS1 and GS2.

There are three scripts of relevance here:
* listAandB.pl
* table2Dist2Nex.pl
* COGnitorParse2full.pl

## Requirements to run these scripts 

The following software is required to run these scripts.

* Perl -- a relatively recent version of Perl, 5.20 and above.  Packages required are ```Getopt::Long``` and ```DBI``` (for connections to MySQL).
* R version 3.5 and above.  This has to be directly accessible from the path. 
* MySQL
* NCBI Blast+.  Executables are accessed via the folder, not necessarilly from the path.
* The COGsoft suite of programs, which have to be compiled locally to work. These are available at [sourceforge.net](https://sourceforge.net/projects/cogtriangles/).  Alternatively the tar file ```COGsoft.201204.tar``` can be found at the FTP location ftp://ftp.ncbi.nih.gov/pub/wolf/COGs/COGsoft.  Executables are accessed via the installation folder, not necessarilly from the path.


## Script description

### listAandB.pl
This is a Perl script that uses ConditionA (for example =>0.8) on columns with headers from ListA and uses ConditionB (for example <=0.4) on columns with headers from ListB on a specified inFile to a specified outFile.

A	running example is:

```perl
./listAandB.pl -listA ArcoCryaerophilusListA -listB ArcoCryaerophilusListB \
-inFile Arco_bsr_matrix_values.txt -outFile test.txt
```

### table2Dist2Nex.pl

A Perl script to take in a table from a set of data and make a simple distance matrix from it that can then be viewed in SplitsTree.  The following input is required at runtime as options:
1. ```metaFile``` a metafile of the items under analyses - just a list of the genomes, in the same order they are in the datafile
2. ```metaHeader```  a declaration of whether the metafile has a header or not - this can be either ```true``` or ```false```
3. ```project```  a project name to find a root folder -- this will have to be adpated to your folder
4. ```inFile``` an input file of data to analyse as a standard table -- the first column can be left in or removed, the code will remove it if necessary
5. ```COGdata``` a description of whether the COG dataset is being used -- values are either ```yes``` or ```no```

A	running example is:

```perl
./table2Dist2Nex.pl -inFile smallInfile -project currentWork -metaFile isolateList \ 
-metaHeader false -COGdata yes
```

### COGnitorParse2full.pl

A	running example is:

```perl

```
