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

		"gunzip -c -d ".$task->{inputfile}." | sed -n \"1~4s/^@/>/p;2~4p\" > \$tmpdir/input.fa",
		"nhmmer --noali -E 0.001 --incE 0.001 --cpu `nproc` -o \$tmpdir/nhmmer.out --tblout \$tmpdir/nhmmer.tlb ".$ENV{PREFIX}."/share/RF00177.stockholm \$tmpdir/input.fa",
		"grep -v \"#\" \$tmpdir/nhmmer.tlb | cut -d \" \" -f1 | sed \"s/^/>/g\" > \$tmpdir/headers.txt",
		"grep -A1 -F -f \$tmpdir/headers.txt \$tmpdir/input.fa | sed \"/^--\$/d\" > \$tmpdir/Extracted16S.fa",
		"julia ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/ARK.jl -i \$tmpdir/Extracted16S.fa -o ".$task->{resultfilename}.".profile -n 10 -t SEK -d ".$ENV{PREFIX}."/share/ -k ".$ENV{PREFIX}."/bin/kmer_counts_per_sequence -s ".$task->{inputfile},
	
	);
}

Utils::executeTasks(\@tasks);
