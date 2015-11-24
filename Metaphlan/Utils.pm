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


1;