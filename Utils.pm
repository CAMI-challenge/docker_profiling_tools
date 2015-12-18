#/usr/bin/env perl

use strict;
use warnings;

package Utils;

our $TYPE_READ_SINGLE = 'single end reads';
our $TYPE_READ_PAIRED = 'paired end reads';
our $TYPE_CONTIGS = 'contigs';

use Data::Dumper;
our @RANKS = ('superkingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species', 'strain');

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
	open (IN, $filename_nodesdmp) || die "can't read NCBI taxonomy node filename '$filename_nodesdmp': $!";
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

sub read_taxonomyMerged {
	my ($filename_mergeddmp) = @_;
	
	my %merged = ();
	print STDERR "reading taxonomy merged nodes ...";
	open (IN, $filename_mergeddmp) || die "cannot read file '$filename_mergeddmp': $!";
		while (my $line = <IN>) {
			my ($old, $new) = split(m/\n|\s*\|\s*/, $line);
			$merged{$old} = $new;
		}
	close (IN);
	print STDERR " done.\n";

	return \%merged;
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

sub rankToLevel {
	#to be able to sort according to the rank, we must somehow know an ordering of the ranks, which is implicitly given by the array RANKS. We here convert a rank to its index position in RANKS.
	my ($rank) = @_;
	
	for (my $i = 0; $i < @RANKS; $i++) {
		return $i if ($rank eq $RANKS[$i]);
	}
	
	return scalar(@RANKS);
}

sub pruneUnwantedRanks {
	#in NCBI taxonomy lineages might exist ranks that are not wanted, cf. RANKS array. We need to recursively traverse the tree and take the children and abundances from those internal nodes and put them to the last wanted rank.
	my ($tree) = @_;
	
	foreach my $taxid (keys(%{$tree->{children}})) {
		if (exists $tree->{children}->{$taxid}->{children}) {
			pruneUnwantedRanks($tree->{children}->{$taxid});
			my $rank = $tree->{children}->{$taxid}->{rank};
			if ( (not isWantedRank($rank, [@Utils::RANKS,'wholeTree', 'unassigned','noMappingFound','Unclassifiable']))) {
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
			if (($rank ne 'no rank') && (not isWantedRank($rank, [@Utils::RANKS,'wholeTree', 'unassigned','noMappingFound','Unclassifiable']))) {
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


sub generateOutput {
	my ($programname, $sampleIDname, $tree, $taxonomydate) = @_;
	
	my $output = "";
	my @resultlines = ();
	Utils::printProfile($tree, \@resultlines);
	$output .= "# Taxonomic Profiling Output\n";
	$output .= '@'."SampleID:".$sampleIDname."\n";
	$output .= '@'."Version:0.9.3\n";
	$output .= '@'."Ranks:".join("|", @Utils::RANKS)."\n";
	$output .= '@'."TaxonomyID:ncbi-taxonomy_".$taxonomydate."\n";
	$output .= '@'."__program__:".$programname."\n";
	$output .= '@@'.join("\t", ('TAXID', 'RANK', 'TAXPATH', 'TAXPATHSN', 'PERCENTAGE'))."\n";
	foreach my $result (sort {(Utils::rankToLevel($a->{rank}) cmp Utils::rankToLevel($b->{rank})) || ($a->{namepath} cmp $b->{namepath})} @resultlines) {
		$output .= "#" if ($result->{taxid} < 1);
		$output .= join("\t", (
			$result->{taxid},
			$result->{rank},
			$result->{taxpath},
			$result->{namepath},
			sprintf("%.6f", $result->{abundance}),
		))."\n";
	}

	return $output;
}

sub collectTasks {
	my $ENV_singleend = 'CONT_FASTQ_FILE_LISTING';
	my $ENV_pairedend = 'CONT_PAIRED_FASTQ_FILE_LISTING';
	my $ENV_contigs = 'CONT_CONTIGS_FILE_LISTING';

	die "environment variable PREFIX is not set!\n" if (not defined $ENV{PREFIX});
	die "environment variable CONT_PROFILING_FILES, which should point to the location of an output directory is not set!\n" if (not defined $ENV{CONT_PROFILING_FILES});
	die "environment variable MAPPERNAME is not set!\n" if (not defined $ENV{MAPPERNAME});

	my @tasks = ();
	foreach my $listing ($ENV_singleend, $ENV_pairedend, $ENV_contigs) {
		if ((defined $ENV{$listing}) && (-e $ENV{$listing})) {
			open (IN, $ENV{$listing}) || die "file '".$ENV{$listing}."' not found: $!";
				while (my $line = <IN>) {
					chomp $line;
					#~ if (-e $line) {
						my $type = "unknown";
						if ($listing eq $ENV_singleend) {
							#call for single end read inputs
							$type = $TYPE_READ_SINGLE;
						} elsif ($listing eq $ENV_pairedend) {
							#call for paired end read inputs
							$type = $TYPE_READ_PAIRED;
						} elsif ($listing eq $ENV_contigs) {
							#call for contig as inputs
							$type = $TYPE_CONTIGS;
						}
						push @tasks, {inputfile => $line, type => $type, resultfilename => $ENV{CONT_PROFILING_FILES}."/result_".(@tasks+1)};
					#~ }
				}
			close (IN);
		}
	}
	
	return \@tasks;
}

sub executeTasks {
	my ($refList_tasks) = @_;
	
	print scalar(@{$refList_tasks})." TASKS TO BE COMPUTED:\n";
	for (my $i = 0; $i < @{$refList_tasks}; $i++) {
		my %task = %{$refList_tasks->[$i]};
		print "".('#' x 80)."\n";
		print "EXECUTING TASK NO. ".($i+1)." of ".scalar(@{$refList_tasks}).":\n\t";
		push @{$task{commands}}, "chmod a+rw ".$task{resultfilename}.".*";
		print join(";\n\t", @{$task{commands}})."\n";
		my $cmdString = join(" ; ", @{$task{commands}});
		my $starttime = time();
		my $skip = 'false';
		if (-e $task{resultfilename}.".profile") {
			my $filesampleid = qx(cat $task{resultfilename}.profile | grep "^\@SampleID:" | cut -d ":" -f 2);
			chomp $filesampleid;
			if ($filesampleid eq $task{inputfile}) {
				$skip = 'true';
			}
		}
		if ($skip eq 'false') {
			print qx(bash -c '$cmdString');
		} else {
			print "\t *** using previously computed results for this input. ***\n";
		}
		my $endtime = time();
		print "\nTASK NO. ".($i+1)." took ".($endtime-$starttime)." seconds to be executed (real time, not CPU time!)\n";
		print "".('#' x 80)."\n\n";
	}
}

1;