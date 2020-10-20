# CconcisusGenomospecies
A repository of scripts used in the genomic analysis of Campylobacter concisus genomospecies GS1 and GS2.

There are three scripts of relevance here:
* listAandB.pl
* table2Dist2Nex.pl
* COGnitorParse2full.pl

## Requirements to run these scripts 

The following software is required to run these scripts.

* R version 3.5 and above.  This has to be directly accessible from the path. 
* MySQL


## Script description

### listAandB.pl
This is a Perl script that uses ConditionA (for example =>0.8) on columns with  headers from ListA and uses ConditionB (for example <=0.4) on columns with headers from ListB on a specified inFile to a specified outFile.

A	running example is:

```perl
./listAandB.pl -listA ArcoCryaerophilusListA -listB ArcoCryaerophilusListB \
-inFile Arco_bsr_matrix_values.txt -outFile test.txt
```

### table2Dist2Nex.pl

A Perl script to take in a table from a set of data and make a simple distance matrix from it that can then be viewed in SplitsTree.  The following input is required at runtime as options:
1. a metafile of the items under analyses - just a list of the genomes, in the same order they are in the datafile
2. a declaration of whether the metafile has a header or not - this can be either ```true``` or ```false```
3. a project name to find a root folder- this will have to be adpated to your folder
4. an input file of data to analyse as a standard table - the first column can be left in or removed, the code will remove it if necessary
5. a description of whether the COG dataset is being used - values are either ```yes``` or ```no```




### COGnitorParse2full.pl

