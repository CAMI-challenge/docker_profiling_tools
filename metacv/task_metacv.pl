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
	
	if ($task->{type} eq $Utils::TYPE_READ_SINGLE) {
		#call for single end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_READ_PAIRED) {
		#call for paired end read inputs
		push @{$task->{commands}}, "rm -rf /tmp/run/*";
		push @{$task->{commands}}, "mkdir -p /tmp/run/";
		push @{$task->{commands}}, "cd /tmp/run/";
		#~ push @{$task->{commands}}, "deinterleave_fastq.sh < <(gunzip -c -d ".$task->{inputfile}.") forward.fastq reverse.fastq";
		push @{$task->{commands}}, "deinterleave.pl <(gunzip -c -d ".$task->{inputfile}.") /tmp/run/forward.fastq /tmp/run/reverse.fastq";
		push @{$task->{commands}}, "metacv classify ".$ENV{PREFIX}."/share/metacv_database/cvk6_2059 forward.fastq reverse.fastq output --threads=".$ENV{NCORES};
		push @{$task->{commands}}, "cp /tmp/run/output.res ".$task->{resultfilename}.".orig";
		push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl /tmp/run/output.res ".$ENV{PREFIX}."/share/taxonomy/ \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	
}

Utils::executeTasks(\@tasks);
