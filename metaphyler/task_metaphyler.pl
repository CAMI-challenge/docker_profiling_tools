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
					my $resultfilename = $ENV{CONT_PROFILING_FILES}."/result_".(@tasks+1);
					my $commonHead = "rm -rf /tmp/run/";
					$commonHead .= "; mkdir -p /tmp/run/";
					$commonHead .= "; cd /tmp/run/";
					if ($listing eq $ENV_singleend) {
						#call for single end read inputs
					} elsif ($listing eq $ENV_pairedend) {
						$commonHead .= "; ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(seqtk seq -a $line) blastn output_n ".$ENV{NCORES};
						$commonHead .= "; ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(seqtk seq -a $line) blastx output_x ".$ENV{NCORES};
					} elsif ($listing eq $ENV_contigs) {
						$commonHead .= "; ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(zcat $line) blastn output_n ".$ENV{NCORES};
						$commonHead .= "; ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/runMetaphyler.pl <(zcat $line) blastx output_x ".$ENV{NCORES};
					}
					my $commonTail = "; ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/combine output_n.classification output_x.classification > ".$resultfilename.".orig";
					$commonTail .= " && perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl $resultfilename.orig ".$ENV{PREFIX}."/share/taxonomy/ \"$line\" > $resultfilename.profile";
					$commonTail .= " && chmod a+rw $resultfilename.*";
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
