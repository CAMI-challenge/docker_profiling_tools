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
		push @{$task->{commands}}, "rm -rf /tmp/run/*";
		push @{$task->{commands}}, "mkdir -p /tmp/run/";
		push @{$task->{commands}}, "cd /tmp/run/";
		push @{$task->{commands}}, "gunzip -c -d ".$task->{inputfile}." | sed -n \"1~4s/^@/>/p;2~4p\" > /tmp/run/input.fa";
		push @{$task->{commands}}, "nhmmer --noali -E 0.001 --incE 0.001 --cpu ".$ENV{NCORES}." -o /tmp/run/nhmmer.out --tblout /tmp/run/nhmmer.tlb ".$ENV{PREFIX}."/share/RF00177.stockholm /tmp/run/input.fa";
		push @{$task->{commands}}, "grep -v \"#\" /tmp/run/nhmmer.tlb | cut -d \" \" -f1 | sed \"s/^/>/g\" > /tmp/run/headers.txt";
		push @{$task->{commands}}, "grep -A1 -F -f /tmp/run/headers.txt /tmp/run/input.fa | sed \"/^--\$/d\" > /tmp/run/Extracted16S.fa";
		push @{$task->{commands}}, "julia ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/ARK.jl -i /tmp/run/Extracted16S.fa -o ".$task->{resultfilename}.".profile -n 10 -t SEK -d ".$ENV{PREFIX}."/share/ -k ".$ENV{PREFIX}."/bin/kmer_counts_per_sequence -s ".$task->{inputfile};
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	
}

Utils::executeTasks(\@tasks);
