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
		
		$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(seqtk seq -a ".$task->{inputfile}.") blastn output_n `nproc`",
		"cp output_n.classification ".$task->{resultfilename}.".orig",
		"perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile",
		
	);
}

Utils::executeTasks(\@tasks);
