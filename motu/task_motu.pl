#!/usr/bin/env perl

use lib "../";
use lib "/biobox/src/IDmapper/";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectTasks()};
foreach my $task (@tasks) {
	$task->{commands} = [];
	
	if ($task->{type} eq $Utils::TYPE_READ_SINGLE) {
		#call for single end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_READ_PAIRED) {
		#call for paired end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	
	push @{$task->{commands}}, "rm -rf /tmp/motus.*";
	push @{$task->{commands}}, "cd /tmp/";
	push @{$task->{commands}}, "perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/mOTUs.pl --processors=".$ENV{NCORES}." ".$task->{inputfile};
	push @{$task->{commands}}, "resfile=`find /tmp/ -name \"*insert.mm.dist.among.unique.scaled.taxaid.gz\"`";
	push @{$task->{commands}}, "zcat \$resfile > ".$task->{resultfilename}.".orig";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl ".$task->{resultfilename}.".orig ".$ENV{PREFIX}."/share/taxonomy/ \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
}

Utils::executeTasks(\@tasks);
