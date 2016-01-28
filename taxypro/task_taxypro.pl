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

		'/home/Tool/uproc-1.2.0/uproc-dna -o '.$task->{resultfilename}.'.orig -s /home/DB/Pfam27/ /home/DB/model/ '.$task->{inputfile},
		$ENV{PREFIX}.'/src/'.$ENV{TOOLNAME}.'/octave.script '.$task->{resultfilename}.'.orig '.$task->{resultfilename}.'.profile '.$task->{inputfile},
		
	);
}

Utils::executeTasks(\@tasks);
