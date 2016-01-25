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
	push @{$task->{commands}}, $ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(seqtk seq -a ".$task->{inputfile}.") blastn output_n `nproc`";
	push @{$task->{commands}}, "cp output_n.classification ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
}

Utils::executeTasks(\@tasks);
