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
  
  sampleID: optional. Set a sample name.\n" if ((@ARGV < 2) || (@ARGV	 > 3));
$sampleIDname = "unknown" if (not defined $sampleIDname);

my $taxonomydate = "unknown";
if (-e $dirWithNCBItaxDump."/taxdump.tar.gz.date") {
	$taxonomydate = qx(cat $dirWithNCBItaxDump/taxdump.tar.gz.date);
	chomp $taxonomydate;
}
my %NCBItaxonomy = %{Utils::read_taxonomytree($dirWithNCBItaxDump."/nodes.dmp")};
my %NCBImerged = %{Utils::read_taxonomyMerged($dirWithNCBItaxDump."/merged.dmp")};

my %frequencies = ();
my $sum = 0;
open (IN, $filename_tooloutput) || die "cannot read orginal input file '$filename_tooloutput': $!\n";
	while (my $line = <IN>) {
		next if ($line =~ m/^taxa\s+abundance/);
		my ($taxid, $frequency) = split(m/\t|\n/, $line);
		if ($taxid eq 'unclassified') {
			$taxid = -1;
		} else {
			if (not exists $NCBItaxonomy{$taxid}) {
				if (not exists $NCBImerged{$taxid}) {
					die "no match for '$line'";
				} else {
					$taxid = $NCBImerged{$taxid};
					if (not exists $NCBItaxonomy{$taxid}) {
						die "no match for '$line'";
					}
				}
			}
		}
		$frequencies{$taxid} += $frequency;
		$sum += $frequency;
	}
close (IN);

my %tree = ();
my %NCBInames = %{Utils::read_taxonomyNames($dirWithNCBItaxDump."/names.dmp")};
foreach my $taxid (sort keys(%frequencies)) {
	my $abundance = 0;
	$abundance = $frequencies{$taxid} / $sum if ($sum > 0);
	my @lineage = ();
	if ($taxid == -1) {
		push @lineage, {taxid => -1, name => 'unassigned', rank => 'unassigned'};
	} else {
		@lineage = @{Utils::getLineage($taxid, \%NCBItaxonomy)};
		Utils::addNamesToLineage(\@lineage, \%NCBInames);
	}
	Utils::addNCBILineage(\%tree, \@lineage, $abundance*100);
}
Utils::pruneUnwantedRanks(\%tree);

print Utils::generateOutput("tipp", $sampleIDname, \%tree, $taxonomydate);
