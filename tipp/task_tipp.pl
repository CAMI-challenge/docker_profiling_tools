#!/usr/bin/env perl

use lib "../";
use lib "/biobox/lib/";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectYAMLtasks()};
foreach my $task (@tasks) {
	$task->{commands} = [];
	
	push @{$task->{commands}}, "rm -rf ".$task->{cacheDir}."/run/";
	push @{$task->{commands}}, "mkdir -p ".$task->{cacheDir}."/run/";
	push @{$task->{commands}}, "cd ".$task->{cacheDir}."/run/";
	push @{$task->{commands}}, "seqtk seq -a ".$task->{inputfile}." > input.fasta";
	push @{$task->{commands}}, "run_abundance.py -f input.fasta -c /root/.sepp/tipp.config -o .";
	push @{$task->{commands}}, "cp abundance.species.csv ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/src/convert.pl ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
}

Utils::executeTasks(\@tasks);
