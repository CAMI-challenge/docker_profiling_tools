#!/usr/bin/env perl

use lib "../";
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
		push @{$task->{commands}}, $ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(seqtk seq -a ".$task->{inputfile}.") blastn output_n ".$ENV{NCORES};
		#~ push @{$task->{commands}}, $ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(seqtk seq -a ".$task->{inputfile}.") blastx output_x ".$ENV{NCORES};
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
		push @{$task->{commands}}, $ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(zcat ".$task->{inputfile}.") blastn output_n ".$ENV{NCORES};
		#~ push @{$task->{commands}}, $ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(zcat ".$task->{inputfile}.") blastx output_x ".$ENV{NCORES};
	}
	
	#~ push @{$task->{commands}}, $ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/combine output_n.classification output_x.classification > ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "cp output_n.classification ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl ".$task->{resultfilename}.".orig ".$ENV{PREFIX}."/share/taxonomy/ \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
}

Utils::executeTasks(\@tasks);
