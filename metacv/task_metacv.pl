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
	
		"deinterleave.pl <(gunzip -c -d ".$task->{inputfile}.") \$tmpdir/forward.fastq \$tmpdir/reverse.fastq",
		"metacv classify \"".$task->{databaseDir}."/cvk6_2059\" forward.fastq reverse.fastq output --threads=`nproc`",
		"cp \$tmpdir/output.res ".$task->{resultfilename}.".orig",
		"perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl \$tmpdir/output.res ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile",
		
	);
}

Utils::executeTasks(\@tasks);
