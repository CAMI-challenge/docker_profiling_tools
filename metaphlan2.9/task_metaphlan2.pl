#!/usr/bin/env perl

use lib "../";
use lib "/biobox/lib/";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectYAMLtasks()};
foreach my $task (@tasks) {
	my $id = $task->{inputfile};
	$id =~ s/ /_/g;
	$id =~ s|/|_|g;
	
	push @{$task->{commands}}, (
		$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/metaphlan2.py ".
		"--input_type fastq ".
		"--nproc `nproc` ".
		"--bowtie2db ".$task->{databaseDir}." ".
		"--index mpa_v29_CHOCOPhlAn_201901 ".
		"--bowtie2out \$tmpdir/out.bowtie2 ".
		"--sample_id '".$id."' ".
		"--CAMI_format_output ".
		"--tmp_dir=/cache ".
		$task->{inputfile}." ".$task->{resultfilename}.".profile",
		"rm \$tmpdir/out.bowtie2",
	);
}

Utils::executeTasks(\@tasks);
