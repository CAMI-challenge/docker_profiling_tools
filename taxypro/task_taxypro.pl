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
		push @{$task->{commands}}, '/home/Tool/uproc-1.2.0/uproc-dna -o '.$task->{resultfilename}.'.orig -s /home/DB/Pfam27/ /home/DB/model/ '.$task->{inputfile};
		push @{$task->{commands}}, $ENV{PREFIX}.'/src/'.$ENV{TOOLNAME}.'/octave.script '.$task->{resultfilename}.'.orig '.$task->{resultfilename}.'.profile '.$task->{inputfile};
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}	
}

Utils::executeTasks(\@tasks);
