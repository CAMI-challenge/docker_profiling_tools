#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Utils;

our @RANKS = ('superkingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species', 'strain');
my ($filename_taxids, $filename_metaphlanoutput) = @ARGV;
die "usage: perl $1 <mapping-file> <metaphylan result file> <NCBI taxonomy file>
  mapping-file: the file holding the one to one mappings from GreenGene to NCBI,
                which should have been created by 'buildIDlists.pl'.

  metaphylan result file: the original result of a metaphylan2 run.\n" if (@ARGV != 2);


my %markerIDs = ();
my $taxonomydate = undef;
open (IN, $filename_taxids) || die;
	while (my $line = <IN>) {
		if ($line =~ m/#NCBI taxonomy downloaded at '(.+?)'/) {
			$taxonomydate = $1;
			next;
		}
		my ($id, $taxid, $lineageString) = split(m/\t|\n/, $line);
		$markerIDs{$id} = lineage_string2object($lineageString);
	}
close (IN);

my %metaphlanTree = ('children', undef);
open (IN, $filename_metaphlanoutput) || die;
	while (my $line = <IN>) {
		next if ($line =~ m/^#/);
		next if ($line !~ m/^k\_\_/); #there might pop up a line holding the "Identifier" of the sample, but it looks like there is no comment symbol. Thus, I relay on the fact that every lineage should start with the superkingdom, i.e. ^k__
		my ($lineageString, $abundance) = split(m/\t|\n/, $line);
		my @lineage = split(m/\|/, $lineageString);
		addLineage(\%metaphlanTree, \@lineage, $abundance);
	}
close (IN);

assignRealAbundance(\%metaphlanTree); #handle cases where a strain like "t__Ruminococcus_gnavus_unclassified" with its abundance points in reality to the according species, i.e. "s__Ruminococcus_gnavus". That might happen on all taxonomic ranks
my @abundanceLeaves = @{printLeafAbundances(\%metaphlanTree)}; #collect all those leaves and maybe branches of the GreenGene tree that holds a "realAbd"

my %NCBItax = ('children', undef, 'rank', 'wholeTree', 'name', 'NCBItaxonomy');
my $idMismappings = -1;
foreach my $taxon (sort @abundanceLeaves) {
	if (exists $markerIDs{$taxon->{name}}) {
		addNCBILineage(\%NCBItax, $markerIDs{$taxon->{name}}, $taxon->{abundance});
	} else {
		#species is unclassified, thus we find some "genus" which is not in the known IDs. Genus name is identical to species first word, thus we look for all species containing genus name and look for the deepest common taxid
		my ($genusName) = ($taxon->{name} =~ m/^g\_\_(.+?)$/);
		my @lineages = ();
		foreach my $ID (keys(%markerIDs)) {
			if ($ID =~ m/^s\_\_$genusName/) {
				#problems occure if it's a virus living in that species. Thus, we add only those lineages that contain the rank "genus"
				my $candidate = $markerIDs{$ID};
				my $candidateSuperkingdom = getRank($candidate, "superkingdom");
				if ((defined $candidateSuperkingdom) && ((($taxon->{lineage} =~ m/k\_\_Bacteria/) && ($candidateSuperkingdom == 2)) || (($taxon->{lineage} =~ m/k\_\_Viruses/) && ($candidateSuperkingdom == 10239)))) {
					push @lineages, $candidate;
				}
			}
		}
		if (@lineages > 0) {
			my @commonLineage = @{Utils::getCommonLineage(\@lineages)};
			addNCBILineage(\%NCBItax, \@commonLineage, $taxon->{abundance})
		} else {
			print STDERR "warnings: could not find a NCBI taxid for '".$taxon->{name}."'. Abundance is added to class 'unassigned'.\n";
			if (not exists $NCBItax{children}->{-1}) {
				$NCBItax{children}->{-1} = {rank => 'unassigned', name => 'unassigned'};
			}
			$NCBItax{children}->{-1}->{children}->{--$idMismappings} = {abundance => $taxon->{abundance}, rank => 'noMappingFound', name => $taxon->{lineage}};
		}
	}
}

markStrains(\%NCBItax);
pruneUnwantedRanks(\%NCBItax);

my @resultlines = ();
printProfile(\%NCBItax, \@resultlines);
print "# Taxonomic Profiling Output\n";
print '@'."SampleID:???\n";
print '@'."Version:0.9.3\n";
print '@'."Ranks:".join("|", @RANKS)."\n";
print '@'."TaxonomyID:ncbi-taxonomy_".$taxonomydate."\n";
print '@@'.join("\t", ('TAXID', 'RANK', 'TAXPATH', 'TAXPATHSN', 'PERCENTAGE'))."\n";
foreach my $result (sort {(rankToLevel($a->{rank}) cmp rankToLevel($b->{rank})) || ($a->{namepath} cmp $b->{namepath})} @resultlines) {
	print "#" if ($result->{taxid} < 1);
	print join("\t", (
		$result->{taxid},
		$result->{rank},
		$result->{taxpath},
		$result->{namepath},
		sprintf("%.6f", $result->{abundance}),
	))."\n";
}

sub rankToLevel {
	#to be able to sort according to the rank, we must somehow know an ordering of the ranks, which is implicitly given by the array RANKS. We here convert a rank to its index position in RANKS.
	my ($rank) = @_;
	
	for (my $i = 0; $i < @RANKS; $i++) {
		return $i if ($rank eq $RANKS[$i]);
	}
	
	return scalar(@RANKS);
}

sub markStrains {
	#the NCBI taxonomy does not seem to know the rank 'strain'. We want to call a rank below a 'species' and with rank name 'no rank' a 'strain', thus we traverse the tree and rename those ranks
	my ($tree, $belowSpecies) = @_;
	
	$belowSpecies = 0 if (not defined $belowSpecies);
	$belowSpecies = ($belowSpecies || ($tree->{rank} eq 'species'));
	foreach my $taxid (keys(%{$tree->{children}})) {
		if (exists $tree->{children}->{$taxid}->{children}) {
			markStrains($tree->{children}->{$taxid}, $belowSpecies);
		} else {
			if ($belowSpecies && ($tree->{children}->{$taxid}->{rank} eq 'no rank')) {
				$tree->{children}->{$taxid}->{rank} = 'strain';
			}
		}
	}
	
}

sub pruneUnwantedRanks {
	#in NCBI taxonomy lineages might exist ranks that are not wanted, cf. RANKS array. We need to recursively traverse the tree and take the children and abundances from those internal nodes and put them to the last wanted rank.
	my ($tree) = @_;
	
	foreach my $taxid (keys(%{$tree->{children}})) {
		if (exists $tree->{children}->{$taxid}->{children}) {
			pruneUnwantedRanks($tree->{children}->{$taxid});
			my $rank = $tree->{children}->{$taxid}->{rank};
			if ( (not isWantedRank($rank, [@RANKS,'wholeTree', 'unassigned','noMappingFound']))) {
				foreach my $childTaxid (keys(%{$tree->{children}->{$taxid}->{children}})) {
					$tree->{children}->{$childTaxid} = $tree->{children}->{$taxid}->{children}->{$childTaxid};
				}
				if (exists $tree->{children}->{$taxid}->{abundance}) {
					$tree->{abundance} += $tree->{children}->{$taxid}->{abundance};
				}
				delete $tree->{children}->{$taxid};
			}
		} else {
			my $rank = $tree->{children}->{$taxid}->{rank};
			if (($rank ne 'no rank') && (not isWantedRank($rank, [@RANKS,'wholeTree', 'unassigned','noMappingFound']))) {
				$tree->{abundance} += $tree->{children}->{$taxid}->{abundance};
				delete $tree->{children}->{$taxid};
			}
		}
	}
}

sub isWantedRank {
	my ($rank, $wantedRanks) = @_;

	foreach my $r (@{$wantedRanks}) {
		return 1 if ($rank eq $r);
	}
	
	return 0;
}

sub printProfile {
	my ($tree, $result, $taxidpath, $namepath, $level) = @_;
	
	#@@TAXID RANK    TAXPATH TAXPATHSN   PERCENTAGE
	my $abundance = 0;
	$abundance += $tree->{abundance} if (exists $tree->{abundance});
	$taxidpath = "" if (not defined $taxidpath);
	$namepath = "" if (not defined $namepath);
	$level = 1 if (not defined $level);
	foreach my $taxid (keys(%{$tree->{children}})) {
		my $descendensAbundance = 0;
		if (not exists $tree->{children}->{$taxid}->{children}) {
			$descendensAbundance = $tree->{children}->{$taxid}->{abundance};
		} else {
			$descendensAbundance = printProfile($tree->{children}->{$taxid}, $result, $taxidpath.$taxid."|", $namepath.$tree->{children}->{$taxid}->{name}."|", ($level+1));
		}
		
		push @{$result}, {
			taxid => $taxid,
			rank => $tree->{children}->{$taxid}->{rank},
			taxpath => $taxidpath.$taxid,
			namepath => $namepath.$tree->{children}->{$taxid}->{name},
			abundance => $descendensAbundance,
			level => $level,
		};
	
		$abundance += $descendensAbundance;
	}
	
	return $abundance;
}

sub getOverallAbundance {
	my ($tree) = @_;
	
	my $abundance = 0;
	$abundance += $tree->{abundance} if (exists $tree->{abundance});
	foreach my $childName (keys(%{$tree->{children}})) {
		$abundance += getOverallAbundance($tree->{children}->{$childName});
	}
	
	return $abundance;
}

sub printLeafAbundances {
	my ($tree, $lineage) = @_;

	$lineage = "" if (not defined $lineage);
	my @leaves = ();
	foreach my $childName (keys(%{$tree->{children}})) {
		if ((exists $tree->{children}->{$childName}->{realAbd}) && ($tree->{children}->{$childName}->{realAbd} != 0)) {
			my $taxName = $childName;
			$taxName =~ s/^t\_\_//;
			push @leaves, {name => $taxName, abundance => $tree->{children}->{$childName}->{realAbd}, lineage => $lineage."|".$childName};
		}
		if (exists $tree->{children}->{$childName}->{children}) {
			push @leaves, @{printLeafAbundances($tree->{children}->{$childName}, $lineage."|".$childName)};
		}
	}
	
	return \@leaves;
}

sub assignRealAbundance {
	my ($tree) = @_;
	
	$tree->{realAbd} = 0;
	foreach my $childName (keys(%{$tree->{children}})) {
		if ($childName =~ m/\_unclassified$/) {
			$tree->{realAbd} += $tree->{children}->{$childName}->{abundance};
			$tree->{children}->{$childName}->{realAbd} = 0;
			#~ if ($childName !~ m/^t__/) {
				#~ $tree->{inherited} = 
				#~ print STDERR "non t__: $childName\n";
			#~ }
		} else {
			$tree->{children}->{$childName}->{realAbd} = $tree->{children}->{$childName}->{abundance};
		}
		assignRealAbundance($tree->{children}->{$childName}) if (exists $tree->{children}->{$childName}->{children});
		
	}
}

sub addNCBILineage {
	my ($tree, $lineage, $abundance) = @_;
	
	if (scalar (@{$lineage}) == 1) {
		if (not exists $tree->{children}->{$lineage->[0]->{taxid}}) {
			$tree->{children}->{$lineage->[0]->{taxid}} = {abundance => $abundance, rank => $lineage->[0]->{rank}};
			$tree->{children}->{$lineage->[0]->{taxid}}->{name} = $lineage->[0]->{name} if (exists $lineage->[0]->{name});
		} else {
			$tree->{children}->{$lineage->[0]->{taxid}}->{abundance} += $abundance;
		}
		#~ print "TA: ".$abundance."\n";
	} else {
		if (not exists $tree->{children}->{$lineage->[0]->{taxid}}) {
			$tree->{children}->{$lineage->[0]->{taxid}} = {children => undef, rank => $lineage->[0]->{rank}};
			$tree->{children}->{$lineage->[0]->{taxid}}->{name} = $lineage->[0]->{name} if (exists $lineage->[0]->{name});
		}
		my @subLineage = @{$lineage};
		shift @subLineage;
		addNCBILineage($tree->{children}->{$lineage->[0]->{taxid}}, \@subLineage, $abundance);
	}
}

sub addLineage {
	my ($tree, $lineage, $abundance) = @_;
	
	if (scalar (@{$lineage}) == 1) {
		$tree->{children}->{$lineage->[0]} = {abundance => $abundance};
	} else {
		if (not exists $tree->{children}->{$lineage->[0]}) {
			$tree->{children}->{$lineage->[0]} = {children => undef};
		}
		my @subLineage = @{$lineage};
		shift @subLineage;
		addLineage($tree->{children}->{$lineage->[0]}, \@subLineage, $abundance);
	}
}

sub lineage_string2object {
	my ($lineagestring) = @_;
	chomp $lineagestring;
	my @lineage = ();
	foreach my $part (split(m/\|/, $lineagestring)) {
		my ($rank, $taxid, $name) = ($part =~ m/^(.+?)=(\d+):?(.*?)$/);
		my $hash = {rank => $rank, taxid => $taxid};
		$hash->{name} = $name if ((defined $name) && ($name ne ''));
		push @lineage, $hash;
	}
	return \@lineage;
}

sub getRank {
	my ($lineage, $rankname) = @_;
	
	foreach my $rank (@{$lineage}) {
		if (lc($rank->{rank}) eq lc($rankname)) {
			return $rank->{taxid};
		}
	}
	
	return undef;
}


