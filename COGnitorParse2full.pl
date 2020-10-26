#!/usr/bin/perl
#
#	Requires MySQL to be installed on the system and accessible via an active DBI connection.
#	Requires R to be installed on the system and directly accessible from the path.
#
#	created by pjb on:		2015-12-29
#	last edited by pjb on:	2020-10-27
#
#	created by Patrick Biggs: p dot biggs at massey dot ac dot nz#
#
#####################

use strict;
use warnings;
use DBI;
use Getopt::Long;

my ($inList, $dataGroup);

GetOptions ('inList:s'		=> \$inList,
			'dataGroup:s'	=> \$dataGroup);

my ($statement, $joiner, $dbh, $sth, $datasource, $querystring, $rowcount, $count);
my ($lGenomeDb, $lQuery, $lHeaderT, $lHeaderC, $newHeader, $newGenome, $localFAA, $curRun, $genus, $species, $strain, $status);


## declare the variables ##

# modify for your path #
my $base		= ("/path/to/your/analysis/data/");

my $root		= ($base . "COGnitorWork/" . $dataGroup . "/");
my $cogRef		= ("/home/pbiggs/dataDrive/pjbData/generalDatabases/COGdata/");
my $COGprog		= ("/home/pbiggs/software/COGsoft.201204/programs/");
my $blastRun	= ("/path/to/your/blast/folder/such/as/ncbi-blast-2.2.30+/bin");

if (-e $root)	{	print ("$root already exists.\n");
} else {			system "mkdir $root";
}

my $log 		= ($root . "logOfActivity.txt");

open (LOG, ">$log") or die ("couldn't open $log: $!\n");

print ("Process started at " . scalar(localtime) . ".\n");
print LOG ("Process started at " . scalar(localtime) . ".\n");

my $temp			= ("temporary4_" . $dataGroup);
my $refCOGName		= ("cognames2003_2014");
my $refCOGtable		= ($cogRef . $refCOGName . ".tab");
my $refFuncName		= ("fun2003_2014");
my $refFuncTable	= ($cogRef . $refFuncName . ".tab");
my $sourceF			= ($root . "basicAnnotation/");
my $COGresults		= ("COGnitorResOn_" . $dataGroup);
my $COGsummary		= ("COGnitorSummaryOn_" . $dataGroup);
my $COGoutput		= ("COGnitorOutputOn_" . $dataGroup);
my $COGoutputF		= ($root . "dataOutputOn_" . $dataGroup . ".txt");
my $COGmatrix		= ("COGnitorMatrixOn_" . $dataGroup);
my $COGmatrixF		= ($root . "dataMatrixOn_" . $dataGroup . ".txt");
my $COGmatrixName	= ("COGnitorMatrixNameOn_" . $dataGroup);
my $COGmatrixNameF	= ($root . "dataMatrixNameOn_" . $dataGroup . ".txt");
my $COGnumber		= ($root . "dataUniq_" . $dataGroup . ".txt");
my $useMatrix3		= ($root . "overallMatrix4_" . $dataGroup . ".txt");
my $useFile			= ($root . $inList);


## connect to the db and load in reference table ##

&dbConnect();

&tableCreate();


## create the required folders ##

my $BLASTss		= ($root . "BLASTss/");
my $BLASTff		= ($root . "BLASTff/");
my $BLASTno		= ($root . "BLASTnn/");
my $BLASTcogn	= ($root . "BLASTcogn/");
my $BLASTdb		= ($root . "BLASTdb/");
my $headers		= ($root . "overallHeaders/");
	
if (-e $BLASTss) {	print ("all the required folders already exist.\n");
} else {			system "mkdir $BLASTss $BLASTff $BLASTno $BLASTcogn $BLASTdb $headers";
}

open (LIST, "<$useFile") or die ("couldn't open $useFile: $!\n");

while (<LIST>) {
	chomp;

	($curRun, $genus, $species, $strain)	= split;
	
	$lGenomeDb		= ($BLASTdb . $strain . "_prot");
	$lQuery			= ($lGenomeDb . ".fa");
	$lHeaderT		= ($headers . $strain . "_header.txt");
	$lHeaderC		= ($headers . $strain . "_header.csv");
	$localFAA		= ($sourceF . "PROKKAon_" . $strain . "/" . $strain . ".faa");

	
	## extract and process the relevant dataset for analysis ##

	&genomeProcess($dataGroup, $strain);


	## the main work ##

	&mainProcess($dataGroup, $strain);	
}

close LIST;


## parse the output into the db and analyse etc ##

&dbConnect();

&summaryTable();

print ("All finished at " . scalar(localtime) . ".\n");
print LOG ("All finished at " . scalar(localtime) . ".\n");

close LOG;


#####################
#					#
#	subroutines		#
#					#
#####################


sub summaryTable {

	## update the table ##

	$sth = $dbh->prepare (qq{alter table $COGresults add genome varchar(25) after geneName});	$sth->execute();	
	$sth = $dbh->prepare (qq{alter table $COGresults add COGcode char(5) default 'n/d'});	$sth->execute();		
	
	$sth = $dbh->prepare (qq{update $COGresults c, $refCOGName r set c.COGcode = r.code where r.COG = c.COG});	$sth->execute();		
	$sth = $dbh->prepare (qq{update $COGresults c, $COGsummary r set c.genome = r.genome where c.geneName = r.geneName});	$sth->execute();
	

	## generate an output summary ##
	
	$sth = $dbh->prepare (qq{drop table if exists $COGoutput});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $COGoutput select codeFunction, code from $refFuncName order by code});	$sth->execute();	
	$sth = $dbh->prepare (qq{insert into $COGoutput values ('not determined', 'n/d')});	$sth->execute();

	my @header	= ('function', 'code');
	
	open (LIST, "<$useFile") or die ("couldn't open $useFile: $!\n");
	
	while (<LIST>) {
		chomp;
	
		($curRun, $genus, $species, $strain)	= split;	

		push(@header, $strain);
	
		$sth = $dbh->prepare (qq{alter table $COGoutput add column $strain mediumint default 0});	$sth->execute();
		$sth = $dbh->prepare (qq{update $COGoutput c, (select COGcode, count(*) as counts from $COGresults where genome = '$strain' group by COGcode) x set c.$strain = x.counts where x.COGcode = c.code});	$sth->execute();
	}
		
	close LIST;

	open (OUT, ">$COGoutputF") or die "$COGoutputF not opened\n";

	print OUT (join("\t", @header), "\n");
	
	$statement = ("SELECT * from $COGoutput");

	&statementPull ($statement, "\t");	

	close OUT;


	## generate absence/presence matrix based on COG ##

	$sth = $dbh->prepare (qq{drop table if exists $COGmatrix});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $COGmatrix select * from $refCOGName order by COG});	$sth->execute();	

	my @header2	= ('COG', 'code', 'COGname');
		
	open (LIST, "<$useFile") or die ("couldn't open $useFile: $!\n");
	
	while (<LIST>) {
		chomp;
	
		($curRun, $genus, $species, $strain)	= split;	

		push(@header2, $strain);
	
		$sth = $dbh->prepare (qq{alter table $COGmatrix add column $strain mediumint default 0});	$sth->execute();
		$sth = $dbh->prepare (qq{update $COGmatrix c, (select COG, count(*) as counts from $COGresults where genome = '$strain' group by COG) x set c.$strain = x.counts where x.COG = c.COG});	$sth->execute();
	}
		
	close LIST;

	open (OUT, ">$COGmatrixF") or die "$COGmatrixF not opened\n";

	print OUT (join("\t", @header2), "\n");
	
	$statement = ("SELECT * from $COGmatrix");

	&statementPull ($statement, "\t");	

	close OUT;


	# find the same number and different number of genes per COG #

	open (IN, "<$COGmatrixF") or die ("couldn't open $COGmatrixF: $!\n");
	open (OUT, ">$COGnumber") or die ("couldn't open $COGnumber: $!\n");

	while (<IN>) {
		chomp;
		my @data	= split ("\t");

#		print (join("\t", @data), "\n");

		if ($data[0] ne 'COG') {

			my $COGcur	= $data[0];
			shift(@data);
			shift(@data);
			shift(@data);
			
			my %counts;
			my @unique = grep !$counts{$_}++, @data;

			my $size	= @unique;
			
#			print ("$size\t----\t$data[0]\n");

			if ($size == 1 && $unique[0] eq '0') {	$status	= ('absent');
			} elsif ($size == 1) {					$status	= ('present');
			} else {								$status	= ('variable');
			}

		print OUT ("$COGcur\t$status\n");	

		}
	}

	close IN;
	close OUT;

	system "rm $COGmatrixF";

	$sth = $dbh->prepare (qq{alter table $COGmatrix add column dataVariable varchar(10) default 'n/a'});	$sth->execute();

	$sth = $dbh->prepare (qq{drop table if exists $temp});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $temp (COG varchar(10), dataVariable varchar(10))});	$sth->execute();	
	$sth = $dbh->prepare (qq{load data local infile '$COGnumber' into table $temp});	$sth->execute();
	$sth = $dbh->prepare (qq{update $COGmatrix c, $temp t set c.dataVariable = t.dataVariable where c.COG = t.COG});	$sth->execute();
	$sth = $dbh->prepare (qq{drop table if exists $temp});	$sth->execute();

	system "rm $COGnumber";


	## generate an allData output ##

	open (OUT, ">$useMatrix3") or die "$useMatrix3 not opened\n";

	print OUT (join("\t", @header2), "\tdataVariable\n");
	
	$statement = ("SELECT * from $COGmatrix");

	&statementPull ($statement, "\t");	

	close OUT;


	## generate a new output file that lists the geneIDs as comma separated ##

	$sth = $dbh->prepare (qq{drop table if exists $COGmatrixName});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $COGmatrixName select * from $COGmatrix});	$sth->execute();
	$sth = $dbh->prepare (qq{alter table $COGmatrixName add index index1(COG)});	$sth->execute();	

	open (LIST, "<$useFile") or die ("couldn't open $useFile: $!\n");
	
	while (<LIST>) {
		chomp;
	
		($curRun, $genus, $species, $strain)	= split;	

		$sth = $dbh->prepare (qq{alter table $COGmatrixName modify column $strain text});	$sth->execute();

		my $geneLists	= ($root . "geneNamesFor" . $strain . ".txt");

		open (COG, "<$refCOGtable") or die ("couldn't open $refCOGtable: $!\n");
		open (G, ">$geneLists") or die ("couldn't open $geneLists: $!\n");
		
		while (<COG>) {
			chomp;		
		
			my @COG	=	split("\t");
		
			my $query2 = qq{select * from $COGresults where genome  = '$strain' and COG = '$COG[0]'};
    		
    		my @names = map {$_->[0]}
        	
        	@{$dbh->selectall_arrayref($query2)};

			my $listJoin	= join(",", @names);
		
			my @complete	= ($COG[0], $strain, $listJoin);

			print G (join("\t", @complete), "\n");
		}

		close COG;
		close G;
		
		
		# load into temporary table and update #
		
		$sth = $dbh->prepare (qq{drop table if exists green});	$sth->execute();		
		$sth = $dbh->prepare (qq{create table green (COG varchar(10), genome varchar(10), hitGenes text)});	$sth->execute();		
		$sth = $dbh->prepare (qq{alter table green add index index1(COG, genome)});	$sth->execute();	
				
		$sth = $dbh->prepare (qq{load data local infile '$geneLists' into table green ignore 1 lines});	$sth->execute();		
		
		$sth = $dbh->prepare (qq{update green r, $COGmatrixName c set c.$strain = r.hitGenes where r.COG = c.COG});	$sth->execute();				

		$sth = $dbh->prepare (qq{drop table if exists green});	$sth->execute();	
		
		system "rm $geneLists";		
	}

	close LIST;


	## generate outputs by gene ##

	open (OUT, ">$COGmatrixNameF") or die "$COGmatrixNameF not opened\n";

	print OUT (join("\t", @header2), "\tdataVariable\n");
	
	$statement = ("SELECT * from $COGmatrixName");

	&statementPull ($statement, "\t");	

	close OUT;
}


sub mainProcess {
	($dataGroup, $strain)	= @_;


	## set up the PSIblasts ##

	my $psiDb		= ($cogRef . "prot2003_2014");
	my $selfOut		= ($BLASTss . "QuerySelfOn" . $strain . ".tab");
	my $segNo		= ($BLASTno . "QueryCOGsOn" . $strain . ".tab");
	my $segYes		= ($BLASTff . "QueryCOGsOn" . $strain . ".tab");
	my $combinedCSV	= ($root . "combinedGenomesOn" . $strain . ".csv");
	my $refCSV		= ($cogRef . "cog2003_2014.csv");
	my $COGout		= ($root . "COGclassifyOn" . $strain . ".csv");
	
	system "psiblast -num_threads 8 -query $lQuery -db $lGenomeDb -show_gis -outfmt 7 -num_descriptions 10 -num_alignments 10 -dbsize 100000000 -comp_based_stats F -seg no -out $selfOut";

	print ("\tSelf PSIblast complete at " . scalar(localtime) . ".\n");	
	print LOG ("\tSelf PSIblast complete at " . scalar(localtime) . ".\n");	

	system "psiblast -num_threads 8 -query $lQuery -db $psiDb -show_gis -outfmt 7 -num_descriptions 1000 -num_alignments 1000 -dbsize 100000000 -comp_based_stats F -seg no -out $segNo";
	
	print ("\tPSIblast without SEG filtering complete at " . scalar(localtime) . ".\n");	
	print LOG ("\tPSIblast without SEG filtering complete at " . scalar(localtime) . ".\n");

	system "psiblast -num_threads 8 -query $lQuery -db $psiDb -show_gis -outfmt 7 -num_descriptions 1000 -num_alignments 1000 -dbsize 100000000 -comp_based_stats T -seg yes -out $segYes";
	
	print ("\tPSIblast with SEG filtering complete at " . scalar(localtime) . ".\n");	
	print LOG ("\tPSIblast with SEG filtering complete at " . scalar(localtime) . ".\n");


	## make the header and hash list ##

	system "cat $lHeaderC $refCSV > $combinedCSV";
	system "$COGprog/COGmakehash -i=$combinedCSV -o=$BLASTcogn -s=\",\" -n=1";
	
	print ("\tHeaders and hash list made at " . scalar(localtime) . ".\n");	
	print LOG ("\tHeaders and hash list made at " . scalar(localtime) . ".\n");


	## make the BLAST table and run COGnitor ##

	system "$COGprog/COGreadblast -d=$BLASTcogn -u=$BLASTno -f=$BLASTff -s=$BLASTss -e=0.1 -q=2 -t=2 -v";
	system "$COGprog/COGcognitor -i=$BLASTcogn -t=$refCSV -q=$combinedCSV -o=$COGout";


	## tidy up with zip ##

	system "gzip $selfOut";
	system "gzip $segNo";
	system "gzip $segYes";
	system "gzip $combinedCSV";


	## load the data into the database ##

	&dbConnect();

	$sth = $dbh->prepare (qq{load data local infile '$COGout' into table $COGresults fields terminated by ','});	$sth->execute();
	
	print ("\tCOGnitor complete at " . scalar(localtime) . ".\n");	
	print LOG ("\tCOGnitor complete at " . scalar(localtime) . ".\n");
	
	return ($dataGroup, $strain);
}


sub genomeProcess {
	($dataGroup, $strain)	= @_;

	if (-e $lQuery) { system "rm $lQuery";
	}
		
	system "cat $localFAA >> $lQuery";
	system "makeblastdb -in $lQuery -dbtype prot -out $lGenomeDb";
	system "grep \">\" $lQuery > $lHeaderT";


	## convert the headers to the required format ##

	open (IN, "<$lHeaderT") or die ("couldn't open $lHeaderT: $!\n");
	open (CSV, ">$lHeaderC") or die ("couldn't open $lHeaderC: $!\n");
	
	while (<IN>) {
		chomp;

		my ($header, $otherBit)	= split('\s');

		if ($header =~ />(\w+)/) {	$newHeader	= $1;
		}	

		my @data	= split("\_", $newHeader);
		
		pop(@data);
		
		$newGenome	= join("\_", @data);
		
		print CSV ("$newHeader,$newGenome\n");
	}
	
	close IN;
	close CSV;

	$sth = $dbh->prepare (qq{load data local infile '$lHeaderC' into table $COGsummary fields terminated by ','});	$sth->execute();
	
	print ("$strain initially processed at " . scalar(localtime) . ".\n");	
	print LOG ("$strain initially processed at " . scalar(localtime) . ".\n");		

	return ($dataGroup, $lGenomeDb, $lQuery, $lHeaderT, $lHeaderC);
}


sub tableCreate {

	## refFuncName table ##

	$sth = $dbh->prepare (qq{drop table if exists $refFuncName});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $refFuncName (code char(5),codeFunction varchar(100))});	$sth->execute();
	$sth = $dbh->prepare (qq{load data local infile '$refFuncTable' into table $refFuncName ignore 1 lines});	$sth->execute();


	## refCOGName table ##

	$sth = $dbh->prepare (qq{drop table if exists $refCOGName});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $refCOGName (COG varchar(10), code char(5) references	$refFuncName.code, COGname varchar(100))});	$sth->execute();
	$sth = $dbh->prepare (qq{load data local infile '$refCOGtable' into table $refCOGName ignore 1 lines});	$sth->execute();
	$sth = $dbh->prepare (qq{alter table $refCOGName add index(COG)});	$sth->execute();


	## $COGsummary ##

	$sth = $dbh->prepare (qq{drop table if exists $COGsummary});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $COGsummary (geneName varchar(35), genome varchar(35))});	$sth->execute();
	$sth = $dbh->prepare (qq{alter table $COGsummary add index(geneName)});	$sth->execute();	


	## $COGresults ##

	$sth = $dbh->prepare (qq{drop table if exists $COGresults});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $COGresults (geneName varchar(35), protLength mediumint, protStart mediumint, protEnd mediumint, cognitorScore float, COG varchar(10) default 'n/d')});	$sth->execute();
	$sth = $dbh->prepare (qq{alter table $COGresults add index(geneName, COG)});	$sth->execute();
	
	print ("Tables created at " . scalar(localtime) . ".\n");	
	print LOG ("Tables created at " . scalar(localtime) . ".\n");	
}


sub dbConnect {
	$count 		= 0;
	$rowcount 	= 0;

	# modify to your database, username and password #

	$datasource = "DBI:mysql:<<database>>;mysql_local_infile=1";
	$dbh = DBI->connect($datasource, '<<username>>', '<<password>>');
	$querystring = '';
}


sub statementPull {
	($statement, $joiner) = @_;

	$sth = $dbh->prepare (qq{$statement});	$sth->execute();
				
	$count++;
				
	while (my @row_items = $sth->fetchrow_array ()) {
		$rowcount++;
		print OUT (join ("$joiner", @row_items), "\n");
		} unless ($rowcount) {
		print OUT ("No data to display\n");
	}

	return ($statement, $joiner);
}
