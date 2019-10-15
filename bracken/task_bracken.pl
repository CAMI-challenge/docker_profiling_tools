#!/usr/bin/env perl

use lib "../";
use lib "/biobox/lib/";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectYAMLtasks()};
foreach my $task (@tasks) {
	my $id = $task->{inputfile};
	$id =~ s/ /_/g;
	$id =~ s|/|_|g;
	
	push @{$task->{commands}}, (
		$ENV{PREFIX}."/src/kraken/kraken2 ".
		"--threads `nproc` ".
		"--gzip-compressed ".
		"--db ".$task->{databaseDir}." ".
		"--output ".$task->{resultfilename}.".kraken ".
		"--report ".$task->{resultfilename}.".kreport ".
		$task->{inputfile},
		"python3 ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/src/est_abundance.py ".
		"-i ".$task->{resultfilename}.".kreport ".
		"-k ".$task->{databaseDir}."/database150mers.kmer_distrib ".
		"-o ".$task->{resultfilename}.".orig",
		"rm ".$task->{resultfilename}.".kraken ",
		"rm ".$task->{resultfilename}.".kreport ",
		$ENV{PREFIX}."/bin/convert.py ".$task->{resultfilename}.".orig"
	);
}

Utils::executeTasks(\@tasks);
