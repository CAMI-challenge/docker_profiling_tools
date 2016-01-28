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
	
		"perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/MarkerScanner.pl -DNA <(gunzip -c ".$task->{inputfile}.")",
		"perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/MarkerAlignTrim.pl -WithReference -OutputFormat phylip",
		"perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/Phylotyping.pl -CPUs `nproc` > ".$task->{resultfilename}.".orig",
		"perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile",
			
	);
}

Utils::executeTasks(\@tasks);
