#!/usr/bin/env perl

use lib "../";
use lib "/biobox/lib/";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectYAMLtasks()};
foreach my $task (@tasks) {
	push @{$task->{commands}}, (
	
		"seqtk seq -a ".$task->{inputfile}." > input.fasta",
		"run_abundance.py -f input.fasta -c /biobox/src/sepp/.sepp/tipp.config -o .",
		"cp abundance.species.csv ".$task->{resultfilename}.".orig",
		"perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile",
		
	);
}

Utils::executeTasks(\@tasks);
