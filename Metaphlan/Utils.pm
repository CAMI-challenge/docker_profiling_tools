#/usr/bin/env perl

use strict;
use warnings;

package Utils;

use Data::Dumper;

sub getCommonLineage {
	my ($lineages) = @_;
	
	my @commonLineage = ();
	for (my $rank = 0; $rank < @{$lineages->[0]}; $rank++) {
		my $rankIsCommon = 'true';
		for (my $i = 1; $i < @{$lineages}; $i++) {
			if (@{$lineages->[$i]} <= $rank) {
				$rankIsCommon = 'false';
				last;
			}
			if ($lineages->[$i]->[$rank]->{taxid} != $lineages->[0]->[$rank]->{taxid}) {
				$rankIsCommon = 'false';
				last;
			}
		}
		if ($rankIsCommon eq 'false') {
			last;
		} else {
			push @commonLineage, $lineages->[0]->[$rank];
		}
	}

	return \@commonLineage;
}

sub printLineage {
	my ($lineage) = @_;
	
	my $res = "";
	foreach my $rank (@{$lineage}) {
		$res .= $rank->{rank}."=".$rank->{taxid};
		$res .= ":".$rank->{name} if (exists $rank->{name});
		$res .= "|";
	}
	$res = substr($res, 0, -1);
	
	return $res;
}

sub guessByName {
	my ($taxon, $taxonomy, $filename_namesdmp) = @_;
	
	my $rank = rankCharToTitle(substr($taxon->{name}, 0, 1));
	my ($id) = ($taxon->{name} =~ m/^\w+\_\_(\w+)/);
	$id = $1 if ($id =~ m/(\w+?)\_/);

	my @candidateLineages = ();
	foreach my $line (split(m/\n/, qx(grep "$id" $filename_namesdmp))) {
		my ($taxid, $name_txt, $unique_name, $name_class) = split(m/\n|\s*\|\s*/, $line);
		if ($name_class eq 'scientific name') {
			my @lineage = @{getLineage($taxid, $taxonomy)};
			if ($lineage[$#lineage]->{rank} eq $rank) {
				push @candidateLineages, \@lineage;
			}
		}
	}

	if (@candidateLineages == 1) {
		return $candidateLineages[0];
	} elsif (@candidateLineages == 0) {
		return [];
	} else {
		die "I had to guess a taxid for '".$taxon->{name}."' and found more than one result. This situation is not yet coverd in my program!\n";
	}
}

sub rankCharToTitle {
	my ($char) = @_;
	
	return 'superkingdom' if ($char eq 'k');
	return 'phylum' if ($char eq 'p');
	return 'class' if ($char eq 'c');
	return 'order' if ($char eq 'o');
	return 'family' if ($char eq 'f');
	return 'genus' if ($char eq 'g');
	return 'species' if ($char eq 's');
	return 'strain' if ($char eq 't');

	die "unknown taxonomic rank character '$char'!\n";
}

sub read_taxonomytree {
	my ($filename_nodesdmp) = @_;
	
	my %taxonomy = ();
	print STDERR "reading taxonomy ...";
	open (IN, $filename_nodesdmp) || die;
		while (my $line = <IN>) {
			my ($taxid, $parent_taxid, $rank) = split(m/\n|\s*\|\s*/, $line);
			$taxonomy{$taxid} = {rank => $rank, parent => $parent_taxid};
		}
	close (IN);
	print STDERR " done.\n";
	
	return \%taxonomy;
}

sub getLineage {
	my ($taxid, $taxonomy) = @_;
	
	return [] if (not defined $taxid);
	my @lineage = ({taxid => $taxid, rank => $taxonomy->{$taxid}->{rank}});
	while ($lineage[0]->{taxid} != 1) {
		unshift @lineage, {
			taxid => $taxonomy->{$lineage[0]->{taxid}}->{parent}, 
			rank => $taxonomy->{$taxonomy->{$lineage[0]->{taxid}}->{parent}}->{rank}
		};
	}
	
	return \@lineage;
}

sub addNamesToLineage {
	my ($lineage, $names) = @_;
	
	for (my $i = 0; $i < @{$lineage}; $i++) {
		$lineage->[$i]->{name} = $names->{$lineage->[$i]->{taxid}};
	}
}

sub read_taxonomyNames {
	my ($filename_namesdmp) = @_;
	
	my %names = ();
	print STDERR "reading taxonomy names ...";
	open (IN, $filename_namesdmp) || die "cannot read file '$filename_namesdmp': $!";
		while (my $line = <IN>) {
			my ($taxid, $name_txt, $unique_name, $name_class) = split(m/\n|\s*\|\s*/, $line);
			if ($name_class eq 'scientific name') {
				$names{$taxid} = $name_txt;
			}
		}
	close (IN);
	print STDERR " done.\n";

	return \%names;
}


1;