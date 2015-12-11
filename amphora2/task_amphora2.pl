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
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	
	push @{$task->{commands}}, "rm -rf /tmp/run";
	push @{$task->{commands}}, "mkdir -p /tmp/run/";
	push @{$task->{commands}}, "cd /tmp/run/";
	push @{$task->{commands}}, "perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/MarkerScanner.pl -DNA <(gunzip -c ".$task->{inputfile}.")";
	push @{$task->{commands}}, "perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/MarkerAlignTrim.pl -WithReference -OutputFormat phylip";
	push @{$task->{commands}}, "perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/Phylotyping.pl -CPUs ".$ENV{NCORES}." > ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl ".$task->{resultfilename}.".orig ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Taxonomy/ \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
}

Utils::executeTasks(\@tasks);
