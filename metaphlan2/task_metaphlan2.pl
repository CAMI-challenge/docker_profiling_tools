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
		"--mpa_pkl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/db_v20/mpa_v20_m200.pkl ".
		"--input_type fastq ".
		"--nproc `nproc` ".
		"--bowtie2db ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/db_v20/mpa_v20_m200 ".
		"--bowtie2out ".$task->{cacheDir}."/run/".$id.".bowtie2 ".
		"--sample_id_key '".$id."' ".
		"--output_file ".$task->{resultfilename}.".orig \"".$task->{inputfile}."\"",
		
		"perl -I ".$ENV{PREFIX}."/lib/ ".$ENV{PREFIX}."/bin/convert.pl ".$ENV{PREFIX}."/share/".$ENV{MAPPERNAME}."/mappingresults.txt ".$task->{resultfilename}.".orig ".$task->{taxonomyDir}." \"".$task->{inputfile}."\" > ".$task->{resultfilename}.".profile";
	);
}

Utils::executeTasks(\@tasks);
