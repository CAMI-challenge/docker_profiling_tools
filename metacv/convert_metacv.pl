#!/usr/bin/env perl

use lib "../";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my ($filename_metacvoutput, $dirWithNCBItaxDump, $sampleIDname) = @ARGV;
die "usage: perl $0 <mapping-file> <metacv result file> <NCBI dump> [sampleID]
  metacv result file: the original result of a metaCV run.
  
  NCBI dump: must point to the directory that holds the unpacked dump 
             of the NCBI taxonomy, or more precise: the two files
             nodes.dmp and names.dmp

  sampleID: optional. Set a sample name.\n" if ((@ARGV < 2) || (@ARGV	 > 3));
$sampleIDname = "unknown" if (not defined $sampleIDname);

my %readCount = ();
my $readSum = 0;
open (IN, $filename_metacvoutput) || die "cannot read metaCV output file '$filename_metacvoutput': $!\n";
	while (my $line = <IN>) {
		my ($read_name, $correlation_score_with_top_matched_gene, $gene_id, $kegg_group_id, $cog_group_id, $taxa_id, $taxa_name) = split(m/\n|\r|\t/, $line);
		$taxa_id = -1 if ($taxa_id eq '_');
		$readCount{$taxa_id}++;
		$readSum++;
	}
close (IN);

my $taxonomydate = "unknown";
if (-e $dirWithNCBItaxDump."/taxdump.tar.gz.date") {
	$taxonomydate = qx(cat $dirWithNCBItaxDump/taxdump.tar.gz.date);
	chomp $taxonomydate;
}
my %NCBItaxonomy = %{Utils::read_taxonomytree($dirWithNCBItaxDump."/nodes.dmp")};
my %NCBImerged = %{Utils::read_taxonomyMerged($dirWithNCBItaxDump."/merged.dmp")};

#update taxonomy to the one which we downloaded
foreach my $taxid (keys(%readCount)) {
	next if ($taxid < 0);
	if (not exists $NCBItaxonomy{$taxid}) {
		if (exists $NCBImerged{$taxid}) {
			my $newTaxid = $NCBImerged{$taxid};
			$readCount{$newTaxid} += $readCount{$taxid};
			delete $readCount{$taxid};
		} else {
			die "cannot find a taxon ID '$taxid'.\n";
		}
	}
}

my %NCBInames = %{Utils::read_taxonomyNames($dirWithNCBItaxDump."/names.dmp")};
my %tree = ();
foreach my $taxid (keys(%readCount)) {
	my @lineage = ();
	if ($taxid < 0) {
		push @lineage, {taxid => -1, name => 'unassigned', rank => 'unassigned'};
	} else {
		@lineage = @{Utils::getLineage($taxid, \%NCBItaxonomy)};
		Utils::addNamesToLineage(\@lineage, \%NCBInames);
	}
	my $abundance = $readCount{$taxid};
	$abundance /= $readSum if ($readSum > 0);
	$abundance *= 100;
	Utils::addNCBILineage(\%tree, \@lineage, $abundance);
}
Utils::pruneUnwantedRanks(\%tree, "noAdding");
print Utils::generateOutput("metacv", $sampleIDname, \%tree, $taxonomydate);
