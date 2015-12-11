#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $ENV_singleend = 'CONT_FASTQ_FILE_LISTING';
my $ENV_pairedend = 'CONT_PAIRED_FASTQ_FILE_LISTING';
my $ENV_contigs = 'CONT_CONTIGS_FILE_LISTING';

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
					my $resultfilename = $ENV{CONT_PROFILING_FILES}."/result_".(@tasks+1)."";
					my $commonHead = "rm -rf /tmp/run/*";
					if ($listing eq $ENV_singleend) {
						#call for single end read inputs
						#~ $resultfilename .= "singleend.txt";
					} elsif ($listing eq $ENV_pairedend) {
						#call for paired end read inputs
						$commonHead .= " && mkdir -p /tmp/run/";
						$commonHead .= " && cd /tmp/run/";
						#~ $commonHead .= " && gunzip -c $line > /tmp/run/input.fastq";
						#~ $commonHead .= " && ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/fastq2fasta /tmp/run/input.fastq /tmp/run/input.fasta";
						#~ $commonHead .= " && rm -f /tmp/run/input.fastq /tmp/run/input.fastq";
						$commonHead .= " && python ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus_cami.py -q <(seqtk seq -a $line) -m 0.001 -c bd -k 8  > $resultfilename.orig";
						$commonHead .= " && python2.7 ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/focus2result.py $resultfilename.orig \"cfk8bd\" $line > $resultfilename.profile";
					} elsif ($listing eq $ENV_contigs) {
						#call for contig as inputs
						#~ $resultfilename .= "contig.txt";
					}
					my $commonTail = "";
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
	print qx(bash -c '$task');
	print "done.\n";
}
