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
	
		'gunzip -c -d '.$task->{inputfile}.' > $tmpdir/input.fastq',
		"julia -p `nproc` /usr/local/sbin/Classify.jl -j /jellyfish/jellyfish-2.2.3/bin/./jellyfish -i \$tmpdir/input.fastq -Q C -d \"".$task->{databaseDir}."\" -k sensitive -o ".$task->{resultfilename}.".profile --normalize -s \"".$task->{inputfile}."\"",
		
	);
}

Utils::executeTasks(\@tasks);
