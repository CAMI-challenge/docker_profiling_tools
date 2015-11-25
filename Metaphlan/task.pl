#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $ENV_singleend = 'CONT_FASTQ_FILE_LISTING';
my $ENV_pairedend = 'CONT_PAIRED_FASTQ_FILE_LISTING';
my $ENV_contigs = 'CONT_CONTIGS_FILE_LISTING';

my ($cores) = @ARGV;
$cores = 1 if (not defined $cores);

die "environment variable PREFIX is not set!\n" if (not defined $ENV{PREFIX});
die "environment variable CONT_PROFILING_FILES is not set!\n" if (not defined $ENV{CONT_PROFILING_FILES});
die "environment variable MAPPERNAME is not set!\n" if (not defined $ENV{MAPPERNAME});

my @tasks = ();
foreach my $listing ($ENV_singleend, $ENV_pairedend, $ENV_contigs) {
	if ((defined $ENV{$listing}) && (-e $ENV{$listing})) {
		open (IN, $ENV{$listing}) || die "file '".$ENV{$listing}."' not found: $!";
			while (my $line = <IN>) {
				chomp $line;
				if (-e $line) {
					my $id = $line;
					$id =~ s/ /_/g;
					$id =~ s|/|_|g;
					my $resultfilename = $ENV{CONT_PROFILING_FILES}."/result_".(@tasks+1)."_";
					my $commonHead = $ENV{PREFIX}."/src/metaphlan2/metaphlan2.py ".
						"--mpa_pkl ".$ENV{PREFIX}."/src/metaphlan2/db_v20/mpa_v20_m200.pkl ".
						"--input_type fastq ".
						"--nproc $cores ".
						"--bowtie2db ".$ENV{PREFIX}."/src/metaphlan2/db_v20/mpa_v20_m200 ".
						"--sample_id_key '".$line."' ";
					if ($listing eq $ENV_singleend) {
						#call for single end read inputs
						$resultfilename .= "singleend.txt";
					} elsif ($listing eq $ENV_pairedend) {
						#call for paired end read inputs
						$resultfilename .= "pairedend.txt";
					} elsif ($listing eq $ENV_contigs) {
						#call for contig as inputs
						$resultfilename .= "contig.txt";
					}
					my $commonTail = "--output_file ".$resultfilename." \"$line\" ";
					$commonTail .= " && perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convertOutput.pl ".$ENV{PREFIX}."/share/".$ENV{MAPPERNAME}."/mappingresults.txt $resultfilename ".$ENV{PREFIX}."/share/".$ENV{MAPPERNAME}."/workdir/ \"$id\" > $resultfilename.profile";
					push @tasks, $commonHead.$commonTail;
				}
			}
		close (IN);
	}
}

my $counter = 1;
print scalar(@tasks)." TASKS TO BE COMPUTED:\n";
foreach my $task (@tasks) {
	print "RUNNING TASK ".($counter++)."/".scalar(@tasks).":\n\t'$task': ...";
	print qx($task);
	print "done.\n";
}
