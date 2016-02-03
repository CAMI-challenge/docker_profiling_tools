#!/usr/bin/env perl

use lib "../";
use lib "/biobox/lib/";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectYAMLtasks(undef, "skipTaxonomyCheck")};
foreach my $task (@tasks) {
	print STDERR "warning: taxonomy is hard coded in program, thus pointing to an alternative taxonomy directory will have no effect.\n" if ($task->{taxonomyDir} ne $ENV{PREFIX}.'/share/taxonomy/');

	push @{$task->{commands}}, (

		'/home/Tool/uproc-1.2.0/uproc-dna -o '.$task->{resultfilename}.'.orig -s /home/DB/Pfam27/ /home/DB/model/ '.$task->{inputfile},
		$ENV{PREFIX}.'/src/'.$ENV{TOOLNAME}.'/octave.script '.$task->{resultfilename}.'.orig '.$task->{resultfilename}.'.profile '.$task->{inputfile},
		
	);
}

Utils::executeTasks(\@tasks);
