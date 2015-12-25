#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my ($input, $frw, $rev) = @ARGV;

open (O_FRW, "> ".$frw) || die "can't write frw: $!";
open (O_REV, "> ".$rev) || die "can't write rev: $!";
open (IN, $input) || die "can't read: $!\n";
	my $out = 'frw';
	while (my $line = <IN>) {
		if ($out eq 'frw') {
			print O_FRW $line;
			print O_FRW scalar(<IN>);
			print O_FRW scalar(<IN>);
			print O_FRW scalar(<IN>);
			$out = 'rev';
		} else {
			print O_REV $line;
			print O_REV scalar(<IN>);
			print O_REV scalar(<IN>);
			print O_REV scalar(<IN>);
			$out = 'frw';
		}
	}
close (IN);
close (O_FRW);
close (O_REV);
