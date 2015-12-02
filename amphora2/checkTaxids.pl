#!/usr/bin/env perl

use lib "../";

use strict;
use warnings;
use Data::Dumper;
use Utils;

my ($contigfile, $dirWithNCBItaxDump) = @ARGV;
die "usage: perl $0 <contig file> <NCBI dump>
  Checks if all taxon IDs in the <contig file> actually exist
  in the dump of the current NCBI taxonomy, which is located in
  NCBI dump.

  contig file: the file holding the accessions and taxon IDs that
               should be checked.

  NCBI dump: must point to the directory that holds the unpacked dump 
             of the NCBI taxonomy, or more precise: the two files
             nodes.dmp and names.dmp\n" if ((@ARGV != 2));

my %NCBItaxonomy = %{Utils::read_taxonomytree($dirWithNCBItaxDump."/nodes.dmp")};

my $missing = "";
open (IN, $contigfile) || die "cannot read contig file '$contigfile': $!\n";
	while (my $line = <IN>) {
		my ($accession, $taxid) = split(m/\t|\n/, $line);
		if (not exists $NCBItaxonomy{$taxid}) {
			$missing .= $line;
		}
	}
close (IN);

if ($missing ne "") {
	die "The following taxon IDs do not exist in the present dump of the NCBI taxonomy.\nPlease correct these lines in '$contigfile' and re-start the docker build.\n";
}
