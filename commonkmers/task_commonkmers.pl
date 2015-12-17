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
		push @{$task->{commands}}, 'gunzip -c -d '.$task->{inputfile}.' > /tmp/run/input.fastq';
		push @{$task->{commands}}, "julia -p ".$ENV{NCORES}.' /usr/local/sbin/Classify.jl -j /jellyfish/jellyfish-2.2.3/bin/./jellyfish -i /tmp/run/input.fastq -Q C -d /exchange/db/CommonKmersData/ -k sensitive -o '.$task->{resultfilename}.'.profile --normalize -s "'.$task->{inputfile}.'"';
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}	
}

Utils::executeTasks(\@tasks);
