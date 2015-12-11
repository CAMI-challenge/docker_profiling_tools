#!/usr/bin/env perl

use lib "../";
use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectTasks()};
foreach my $task (@tasks) {
	$task->{commands} = [];
	
	if ($task->{type} eq $Utils::TYPE_READ_SINGLE) {
		#call for single end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_READ_PAIRED) {
		#call for paired end read inputs
		push @{$task->{commands}}, "rm -rf /tmp/run/*";
		push @{$task->{commands}}, "mkdir -p /tmp/run/";
		push @{$task->{commands}}, "cd /tmp/run/";
		push @{$task->{commands}}, "python ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus_cami.py -q <(seqtk seq -a ".$task->{inputfile}.") -m 0.001 -c bd -k 8  > ".$task->{resultfilename}.".orig";
		push @{$task->{commands}}, "python2.7 ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus2result.py ".$task->{resultfilename}.".orig \"cfk8bd\" ".$task->{inputfile}." > ".$task->{resultfilename}.".profile";
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	
}

Utils::executeTasks(\@tasks);
