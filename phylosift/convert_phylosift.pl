#!/usr/bin/env perl

use lib "../";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my ($phylosiftoutputfile, $dirWithNCBItaxDump, $sampleIDname) = @ARGV;
die "usage: perl $0 <mapping-file> <NCBI dump> [sampleID]
  mapping-file: result file of the phylosift run, names 'taxasummary.txt'.

  NCBI dump: must point to the directory that holds the unpacked dump 
             of the NCBI taxonomy, or more precise: the two files
             nodes.dmp and names.dmp

  sampleID: optional. Set a sample name.\n" if ((@ARGV < 2) || (@ARGV > 3));
$sampleIDname = "unknown" if (not defined $sampleIDname);

my @taxa = ();
push @taxa, {
	taxid => -1, 
	name => 'unassigned', 
	readcount => 0, 
	lineage => [{taxid => -1, name => 'unassigned', rank => 'unassigned'}],
	rank => 'unassigned',
};
my $totalreads = 0;
open (IN, $phylosiftoutputfile) || die "can't read file '$phylosiftoutputfile': $!\n";
	while (my $line = <IN>) {
		next if ($line =~ m/^#/);
		if ($line !~ m/^\d+/) {
			if ($line =~ m/^Unclassifiable/) {
				my ($taxid, $rank, $name, $reads) = split(m/\t|\n/, $line);
				my @lineage = @{$taxa[0]->{lineage}};
				push @lineage, {taxid => $taxa[0]->{taxid}-1, name => $taxid, rank => $taxid};
				push @taxa, {taxid => $lineage[$#lineage]->{taxid}, readcount => $reads, name => $lineage[$#lineage]->{name}, lineage => \@lineage};			
				$totalreads += $reads;
			}
			next;
		}
		my ($taxid, $rank, $name, $reads) = split(m/\t|\n/, $line);
		push @taxa, {taxid => $taxid, readcount => $reads};
		$totalreads += $reads;
	}
close (IN);

my %tree = ();
my %NCBItaxonomy = %{Utils::read_taxonomytree($dirWithNCBItaxDump."/nodes.dmp")};
my %NCBInames = %{Utils::read_taxonomyNames($dirWithNCBItaxDump."/names.dmp")};
foreach my $taxon (@taxa) {
	if ($totalreads > 0) {
		$taxon->{abundance} = $taxon->{readcount} / $totalreads * 100;
	} else {
		$taxon->{abundance} = 0;
	}
	delete $taxon->{readcount};
	if ($taxon->{taxid} > 0) {
		$taxon->{lineage} = Utils::getLineage($taxon->{taxid}, \%NCBItaxonomy);
		Utils::addNamesToLineage($taxon->{lineage}, \%NCBInames);
	}
	Utils::addNCBILineage(\%tree, $taxon->{lineage}, $taxon->{abundance});
}

Utils::pruneUnwantedRanks(\%tree);
my $taxonomydate = "unknown";
if (-e $dirWithNCBItaxDump."/taxdump.tar.gz.date") {
	$taxonomydate = qx(cat $dirWithNCBItaxDump/taxdump.tar.gz.date);
	chomp $taxonomydate;
}

print Utils::generateOutput("phylosift", $sampleIDname, \%tree, $taxonomydate);
