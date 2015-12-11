#!/usr/bin/env perl

use lib "../";
use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectTasks()};
foreach my $task (@tasks) {
	$task->{commands} = [];
	
	push @{$task->{commands}}, 
		$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/phylosift all ".
		"--disable_updates ".
		"--simple ".
		"-f ".
		"--output /tmp/phylosift_run/ ".
		"--threads ".$ENV{NCORES}." ".
		#~ "--chunks 10 ".
		#~ "--chunk_size 10 ".
		"--keep_search ";
	if ($task->{type} eq $Utils::TYPE_READ_SINGLE) {
		#call for single end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_READ_PAIRED) {
		#call for paired end read inputs
		$task->{commands}->[0] .= "--paired ";
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	$task->{commands}->[0] .= $task->{inputfile};
	
	push @{$task->{commands}}, "cp /tmp/phylosift_run/taxasummary.txt ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl ".$task->{resultfilename}.".orig ".$ENV{HOME}."/share/phylosift/ncbi/ \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
}

Utils::executeTasks(\@tasks);

