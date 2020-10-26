#!/usr/bin/perl
#
#	a script to take in a table from a set of data and make a simple distance
#	matrix from it that can then be viewed in splitsTree.  The following
#	input is required:
#		1) a metafile of the items under analyses
#			- just a list of the genomes, in the same order they are in the
#			datafile
#		2) a declaration of whether the metafile has a header or not
#			- this can be either 'true' or 'false'
#		3) a project name to find a root folder
#			- this will have to be adpated to your folder
#		4) an input file of data to analyse as a standard table.
#			- the first column can be left in or removed, the code will remove
#			it if necessary
#		5) a description of whether the COG dataset is being used - [yes|no]
#
#	Requires R to be installed on the system and directly accessible from the path.
#
#	created by pjb on:		2015-12-29
#	last edited by pjb on:	2020-10-27
#
#	created by Patrick Biggs: p dot biggs at massey dot ac dot nz
#
###############################

use strict;
use warnings;
use Getopt::Long;

my ($inFile, $project, $metaFile, $metaHeader, $COGdata);

GetOptions ('project:s'		=> \$project,
			'inFile:s'		=> \$inFile,
			'metaFile:s'	=> \$metaFile,
			'metaHeader:s'	=> \$metaHeader,
			'COGdata:s'		=> \$COGdata);

my ($curP, $empty, $root, $distName, $size, $distType);

my @P	= (1, 2);


## find the folder by projectName ##

&projectHunter($project, $empty);


## on with the work ##

my $resF		= ($root . "Results4_" . $project . "/");
my $log 		= ($root . "logOfActivity4_" . $project . ".txt");
my $useFile		= ($root . $inFile . ".txt");
my $modFile		= ($root . $inFile . "_Mod.txt");
my $useMeta		= ($root . $metaFile . ".txt");


open (LOG, ">$log") or die ("couldn't open $log: $!\n");

print ("Process started at " . scalar(localtime) . ".\n");
print LOG ("Process started at " . scalar(localtime) . ".\n");

if  (-e $resF) { 	print "Required folder already exists.\n";
} else {			system "mkdir $resF";
}


## read in metadata to get data size ##

my @numbers;

&metaCheck($useMeta, $empty);


## check the data file and edit it ##

&dataMod($useFile, $modFile, $size);


## do the actual work ##

foreach $curP(@P) {
	&Rwork($resF, $modFile, $curP);
}

print ("All finished at " . scalar(localtime) . ".\n");
print LOG ("All finished at " . scalar(localtime) . ".\n");

close LOG;


#####################
#					#
#	subroutines		#
#					#
#####################

sub metaCheck {
	($useMeta, $empty)	= @_;

	open (LIST, "<$useMeta") or die ("couldn't open $useMeta: $!\n");

	while (<LIST>) {
		chomp;
		my @meta	= split ("\t");
		push (@numbers, $meta[0]);
	}

	close LIST;

	$size = @numbers;

	if ($metaHeader eq 'false') {		print "No need to change anything here.\n";
	} elsif ($metaHeader eq 'true') {	$size = $size - 1;
	}

	print ("We are working with $size genomes this time at " . scalar(localtime) . ".\n");
	print LOG ("We are working with $size genomes this time at " . scalar(localtime) . ".\n");

	return ($useFile, $size);
}


sub dataMod {
	($useFile, $modFile, $size)	= @_;

	open (IN, "<$useFile") or die ("couldn't open $useFile: $!\n");
	open (OUT, ">$modFile") or die ("couldn't open $modFile: $!\n");

	while (<IN>) {
		chomp;
		my @meta		= split ("\t");
		
		if ($COGdata eq 'yes') {
			pop(@meta);
			shift(@meta);
			shift(@meta);
			shift(@meta);				
		}
					
		my $metaSize	= @meta;

		print ("Our data array is $metaSize elements wide.\n");

		if ($metaSize == $size) {
			print ("\tHmm, our data has not lost the first column by the looks of it.\n");
			print OUT (join("\t", @meta), "\n");
		} elsif ($metaSize == $size + 1) {
			print ("\tOK, we have to lose the first column.\n");
			shift(@meta);
			print OUT (join("\t", @meta), "\n");
		} else {
			print ("\tSomething's not right here.\n");
		}
	}

	close IN;
	close OUT;

	print ("We have checked the input file at " . scalar(localtime) . ".\n");
	print LOG ("We have checked the input file at " . scalar(localtime) . ".\n");

	return ($useFile, $modFile, $size);
}


sub Rwork {
	($resF, $modFile, $curP)	= @_;

	if ($curP == 1) {		$distType = "Manhattan";
	} elsif ($curP == 2) {	$distType = "Euclidean";
	}

	my $compact		= ($project . "_". $distType);
	my $R 			= ($resF . $compact . ".r");
	my $outR		= ($resF . $compact . "Data.txt");
	my $cleanR		= ($resF . $compact . "DataClean.txt");
	my $nex			= ($resF . $compact . ".nex");
	my $image		= ($resF . $compact . "Image.svg");

	
	## write the R code to analyse ##
	#
	#	gene_dist(Ttest1, d=gene_row_dist2, w=1, p=1) # Manhattan
	#	gene_dist(Ttest1, d=gene_row_dist2, w=1, p=2) # Euclidean
	#
	########
	
	open (R, ">$R") or die ("couldn't open $R: $!\n");

	print R ("setwd(\"$resF\")\n");
	print R ("test1<-read.table(\"$modFile\", header=TRUE)\n");
	print R ("\n");
	print R ("Ttest1<-t(test1)\n");
	print R ("x<-Ttest1\n\n");
	print R ("gene_row_dist2 <- function(x1, x2, w=1, p=$curP) {\n");
	print R ("  d <- ifelse(x1 == 0, ifelse(x2 == 0, 0, w*(x2-1) + 1), ifelse(x2 == 0, w*(x1-1) + 1, w*abs(x2-x1)))\n");
	print R ("sum(d^p)^(1/p)\n");
	print R ("}\n\n");
	print R ("gene_dist <- function(x, w=1, p=$curP, d=gene_row_dist2) {\n");
	print R ("  m <- matrix(NA, nrow(x), nrow(x))\n");
	print R ("  for (i in 1:nrow(x)) {\n");
	print R ("    for (j in i:nrow(x)) {\n");
	print R ("      m[i,j] <- m[j,i] <- d(x[i,], x[j,], w, p) \n");
	print R ("    }\n");
	print R ("  }\n");
	print R ("  rownames(m)<-rownames(Ttest1)\n");
	print R ("  colnames(m)<-rownames(Ttest1) \n");
	print R ("  as.dist(m, diag=TRUE)\n");
	print R ("}\n\n");
	print R ("M <- as.matrix(gene_dist(Ttest1, d=gene_row_dist2, w=1, p=$curP))\n");
	print R ("M[upper.tri(M)] <- \"\"\n");
    print R ("write.table(M, file=\"$outR\")\n");
	close R;

	system "R --vanilla < $R";

	system "cat $outR | perl -lpe 's/\"//g' > $cleanR";


	## create the triangle and the nexus file ##

	open (NEX, ">$nex") or die ("couldn't open $nex: $!\n");

	print NEX ("#NEXUS\n\n");
	print NEX ("BEGIN taxa;\n");
	print NEX ("\tDIMENSIONS ntax = $size;\n");
	print NEX ("END;\n\n");
	print NEX ("BEGIN distances;\n");
	print NEX ("\tDIMENSIONS ntax = $size;\n");
	print NEX ("\tFORMAT\n");
	print NEX ("\t\ttriangle=LOWER\n");
	print NEX ("\t\tdiagonal\n");
	print NEX ("\t\tlabels\n");
	print NEX ("\t\tmissing=?\n");
	print NEX ("\t;\n\n");
	print NEX ("MATRIX\n");

	open (IN, "<$cleanR") or die ("couldn't open $cleanR: $!\n");

	while (<IN>) {
		chomp;
		my @tri	= split;

		if ($tri[$size -1 ] =~ /\_/) {
			print ("Ignore the first line");
		} else {
			print NEX ("$_\n");
		}
	}

	close IN;

	print NEX (";\nEND;\n");

	close NEX;

	print ("\t completed the work on $compact at " . scalar(localtime) . ".\n");
	print LOG ("\t completed the work on $compact at " . scalar(localtime) . ".\n");

	return ($resF, $modFile, $curP);
}


sub projectHunter {
	($project, $empty)	= @_;

	if ($project eq 'projectName') {	
		$root 	= ("/path/to/your/analysis/data/");				
	} else {
		print ("\nPlease check your project name, as it may be incorrect.\n\\n");
	}

	return ($project, $root);
}
