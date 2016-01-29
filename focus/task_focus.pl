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

		"python ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus_cami.py -q <(seqtk seq -a ".$task->{inputfile}.") -m 0.001 -c bd -k 8  > ".$task->{resultfilename}.".orig",
		"python2.7 ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus2result.py ".$task->{resultfilename}.".orig \"cfk8bd\" ".$task->{inputfile}." > ".$task->{resultfilename}.".profile",
		
	);
}

Utils::executeTasks(\@tasks);
