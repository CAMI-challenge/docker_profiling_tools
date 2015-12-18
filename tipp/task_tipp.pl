#!/usr/bin/env perl

use lib "../";
use lib "/biobox/src/IDmapper/";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectTasks()};
foreach my $task (@tasks) {
	$task->{commands} = [];
	
	push @{$task->{commands}}, "rm -rf /tmp/run/";
	push @{$task->{commands}}, "mkdir -p /tmp/run/";
	push @{$task->{commands}}, "cd /tmp/run/";

	if ($task->{type} eq $Utils::TYPE_READ_SINGLE) {
		#call for single end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_READ_PAIRED) {
		#call for paired end read inputs
		push @{$task->{commands}}, "seqtk seq -a ".$task->{inputfile}." > input.fasta";
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	
	push @{$task->{commands}}, "run_abundance.py -f input.fasta -c /root/.sepp/tipp.config -o .";
	push @{$task->{commands}}, "cp abundance.species.csv ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl ".$task->{resultfilename}.".orig ".$ENV{PREFIX}."/share/taxonomy/ \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
}

Utils::executeTasks(\@tasks);
