#!/usr/bin/perl
# 
#	a Perl script that uses ConditionA (for example => 0.8) on columns with 
#	headers from ListA and uses ConditionB (for example <= 0.4) on columns 
#	with headers from ListB on a specified inFile to a specified outFile.
#
#	running example:
#	./listAandB.pl -listA ArcoCryaerophilusListA -listB ArcoCryaerophilusListB 
#		-inFile Arco_bsr_matrix_values.txt -outFile test.txt
#
#
#	Requires R to be installed on the system and directly accessible from the path.
#
#	created by Patrick Biggs: p dot biggs at massey dot ac dot nz
#
#####################

use strict;
use warnings;
use Getopt::Long;

my ($listA, $listB, $inFile, $outFile);

GetOptions ('listA:s'	=> \$listA,
			'listB:s'	=> \$listB,
			'inFile:s'	=> \$inFile,
			'outFile:s'	=> \$outFile);


## modify for your path ##
my $root	= ("/path/to/your/analysis/data/");

my $useFile		= ($root . $inFile);
my $useListA	= ($root . $listA);
my $useListB	= ($root . $listB);
my $combined	= ($root . "currentCombined");
my $log 		= ($root . "logOfProcess.txt");
my $counter		= 0;
my $R			= ($root . "runR.r");
my $result		= ($root . $outFile);
my $newCount	= 0;

open (LOG, ">$log") or die ("couldn't open $log: $!\n");

print ("Process started at " . scalar(localtime) . ".\n");
print LOG ("Process started at " . scalar(localtime) . ".\n");


## make the combined list ##

open (A, "<$useListA") or die ("couldn't open $useListA: $!\n");
open (B, "<$useListB") or die ("couldn't open $useListB: $!\n");
open (OUT, ">$combined") or die ("couldn't open $combined: $!\n");


## can change values here for this section and in the below ##

while (<A>) {
	chomp;
	my @gene	= split;
	print OUT ("$gene[0]\t>=0.8\n");
	$counter++;
}

while (<B>) {
	chomp;
	my @gene	= split;
	print OUT ("$gene[0]\t<=0.4\n");
	$counter++;
}

close A;
close B;
close OUT;

print ("You have $counter rows in this dataset.\n");
print LOG ("You have $counter rows in this dataset.\n");


## run at R ##

open (R, ">$R") or die ("couldn't open $R: $!\n");

print R ("setwd(\"$root\")\n"); 
print R ("test_data <- read.table(\"$inFile\", header=T, row.names=1, sep=\"\\t\")\n"); 
print R ("ourSubset<-subset(test_data,\n");

open (IN, "<$combined") or die ("couldn't open $combined: $!\n");

while (<IN>) {
	chomp;
	my ($newGene, $condition)	= split;
	
	if ($newCount != $counter - 1) {	print R ("test_data['$newGene'] $condition & \n");	
	} else {							print R ("test_data['$newGene'] $condition, \n");	
	}
	$newCount++;
}

close IN;

print R ("select=c(\n");

$newCount	= 0;

open (IN, "<$combined") or die ("couldn't open $combined: $!\n");

while (<IN>) {
	chomp;
	my ($newGene, $condition)	= split;
	
	if ($newCount != $counter - 1) {	print R ("'$newGene', ");	
	} else {							print R ("'$newGene'");	
	}
	$newCount++;
}

close IN;

print R ("))\n");
print R ("write.table(ourSubset, file = \"$outFile\", row.names = TRUE, col.names = TRUE, sep=\"\\t\")\n");

close R;

system "R --vanilla < $R";

print ("All finished at " . scalar(localtime) . ".\n");
print LOG ("All finished at " . scalar(localtime) . ".\n");

close LOG;
