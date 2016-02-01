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
	
		"cd ",
		$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/phylosift all ".
		"--disable_updates ".
		"--simple ".
		"-f ".
		"--output \$tmpdir ".
		"--threads `nproc` ".
		#~ "--chunks 10 ".
		#~ "--chunk_size 10 ".
		"--keep_search ".
		"--paired ".
		$task->{inputfile},
		"cp \$tmpdir/taxasummary.txt ".$task->{resultfilename}.".orig",
		"perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile",
	);
}

Utils::executeTasks(\@tasks);

