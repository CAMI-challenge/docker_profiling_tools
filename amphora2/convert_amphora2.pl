#!/usr/bin/env perl

use lib "../";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my ($filename_tooloutput, $dirWithNCBItaxDump, $sampleIDname) = @ARGV;
die "usage: perl $0 <original tool result file> <NCBI dump> [sampleID]
  tool result file: the original result of the original tool run.
  
  NCBI dump: must point to the directory that holds the unpacked dump 
             of the NCBI taxonomy, or more precise: the two files
             nodes.dmp and names.dmp

  sampleID: optional. Set a sample name.\n" if ((@ARGV < 3) || (@ARGV	 > 4));
$sampleIDname = "unknown" if (not defined $sampleIDname);

my %frequencies = ();
my $sum = 0;
open (IN, $filename_tooloutput) || die "cannot read orginal input file '$filename_tooloutput': $!\n";
	while (my $line = <IN>) {
		next if ($line =~ m/^Query\s+Marker/);
		my ($query, $marker, @lineage) = split(m/\t|\n/, $line);
		$frequencies{$lineage[$#lineage]}++;
		$sum++;
	}
close (IN);

my $taxonomydate = "unknown";
if (-e $dirWithNCBItaxDump."/taxdump.tar.gz.date") {
	$taxonomydate = qx(cat $dirWithNCBItaxDump/taxdump.tar.gz.date);
	chomp $taxonomydate;
}

my %tree = ();
my %NCBItaxonomy = %{Utils::read_taxonomytree($dirWithNCBItaxDump."/nodes.dmp")};
my %NCBInames = %{Utils::read_taxonomyNames($dirWithNCBItaxDump."/names.dmp")};
foreach my $taxid (sort keys(%frequencies)) {
	my @lineage = @{Utils::getLineage($taxid, \%NCBItaxonomy)};
	Utils::addNamesToLineage(\@lineage, \%NCBInames);
	my $abundance = 0;
	$abundance = $frequencies{$taxid} / $sum if ($sum > 0);
	Utils::addNCBILineage(\%tree, \@lineage, $abundance*100);
}
Utils::pruneUnwantedRanks(\%tree);

print Utils::generateOutput("amphora2", $sampleIDname, \%tree, $taxonomydate);
