# CconcisusGenomospecies
A repository of scripts used in the genomic analysis of Campylobacter concisus genomospecies GS1 and GS2.

There are three scripts of relevance here:
* listAandB.pl
* table2Dist2Nex.pl
* COGnitorParse2full.pl

## Requirements to run these scripts 

### general

* R version 3.5 and above.  This has to be directly accessible from the path. 
* MySQL


## Script description

### listAandB.pl
This is a Perl script that uses ConditionA (for example =>0.8) on columns with  headers from ListA and uses ConditionB (for example <=0.4) on columns with headers from ListB on a specified inFile to a specified outFile.

A	running example is:

```perl
./listAandB.pl -listA ArcoCryaerophilusListA -listB ArcoCryaerophilusListB -inFile Arco_bsr_matrix_values.txt -outFile test.txt
```

### table2Dist2Nex.pl


### COGnitorParse2full.pl

