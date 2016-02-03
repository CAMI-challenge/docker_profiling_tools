#!/usr/bin/env perl

use strict;
use warnings;

my ($targetDir, $moreFiles) = @ARGV;
die "Downloads a dump of the taxonomy database from NCBI into the target directory.\nArchive will be extracted and a time stamp added.\nUsage: perl $0 <target dir> <extractMore>\n" if (@ARGV < 1 || @ARGV > 2);

system("mkdir -p $targetDir") if (not -d $targetDir);
print STDERR "downloading taxdump ...";
system("wget -q -O $targetDir/taxdump.tar.gz ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz");
print STDERR " done.\nextracting ...";
system("tar -C $targetDir/ -xzvf $targetDir/taxdump.tar.gz names.dmp nodes.dmp merged.dmp ");
system("tar -C $targetDir/ -xzvf $targetDir/taxdump.tar.gz delnodes.dmp") if (defined $moreFiles);
print STDERR " done.\n";
system("rm -f $targetDir/taxdump.tar.gz");
system("date +\"%Y.%m.%d\" > $targetDir/taxdump.tar.gz.date");
