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
	
		"perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/mOTUs.pl --processors=`nproc` ".$task->{inputfile},
		"resfile=`find \$tmpdir -name \"*insert.mm.dist.among.unique.scaled.taxaid.gz\"`",
		"gunzip -c -d \$resfile > ".$task->{resultfilename}.".orig",
		"perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile",
	
	);
}

Utils::executeTasks(\@tasks);
