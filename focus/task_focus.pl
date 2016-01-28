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

		"python ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus_cami.py -q <(seqtk seq -a ".$task->{inputfile}.") -m 0.001 -c bd -k 8  > ".$task->{resultfilename}.".orig",
		"python2.7 ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus2result.py ".$task->{resultfilename}.".orig \"cfk8bd\" ".$task->{inputfile}." > ".$task->{resultfilename}.".profile",
		
	);
}

Utils::executeTasks(\@tasks);
