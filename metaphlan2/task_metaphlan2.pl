#!/usr/bin/env perl

use lib "../";
use strict;
use warnings;
use Data::Dumper;
use Utils;

my @tasks = @{Utils::collectTasks()};
foreach my $task (@tasks) {
	$task->{commands} = [];
	
	my $id = $task->{inputfile};
	$id =~ s/ /_/g;
	$id =~ s|/|_|g;
	
	if ($task->{type} eq $Utils::TYPE_READ_SINGLE) {
		#call for single end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_READ_PAIRED) {
		#call for paired end read inputs
	} elsif ($task->{type} eq $Utils::TYPE_CONTIGS) {
		#call for contig as inputs
	}
	
	push @{$task->{commands}}, 
		$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/metaphlan2.py ".
		"--mpa_pkl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/db_v20/mpa_v20_m200.pkl ".
		"--input_type fastq ".
		"--nproc ".$ENV{NCORES}." ".
		"--bowtie2db ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/db_v20/mpa_v20_m200 ".
		"--bowtie2out /tmp/".$id.".bowtie2 ".
		"--sample_id_key '".$id."' ".
		"--output_file ".$task->{resultfilename}.".orig \"".$task->{inputfile}."\"";
	push @{$task->{commands}}, "perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert_".$ENV{TOOLNAME}.".pl ".$ENV{PREFIX}."/share/".$ENV{MAPPERNAME}."/mappingresults.txt ".$task->{resultfilename}.".orig ".$ENV{PREFIX}."/share/".$ENV{MAPPERNAME}."/workdir/ \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";	
}

Utils::executeTasks(\@tasks);
