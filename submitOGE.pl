#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my %programs = ();
$programs{amphora2} 	= {ram => 10}; #ram in GB
$programs{focus} 			= {ram => 10}; #ram in GB
$programs{metaphlan2} 	= {ram => 10}; #ram in GB
$programs{metaphyler} 	= {ram => 40}; #ram in GB
$programs{motu} 				= {ram => 10}; #ram in GB
$programs{phylosift} 		= {ram => 40}; #ram in GB

my ($toolname, $justprint) = @ARGV;
die "usage: perl $0 <toolname> [justprint]\n  toolname = name of the profiling tool to run on the cluster.\n  justprint = if defined, just print the content of the cluster script to STDOUT, but don't actually submit.\n" if (@ARGV < 1 || @ARGV > 2);

my $script = createScript($ARGV[0]);
if (defined $script) {
	if (defined $justprint) {
		print $script;
	} else {
		my $scriptfilename = "tmp_clusterscript.sh";
		open (OUT, "> $scriptfilename") || die "cannot write: $!";
			print OUT $script;
		close (OUT);
		print qx(qsub $scriptfilename);
		unlink $scriptfilename;
	}
}

sub createScript {
	my ($toolname) = @_;
	
	my $found = 'false';
	foreach my $name (keys(%programs)) {
		if ($name eq $toolname) {
			$found = 'true';
			last;
		}
	}
	die "No task with name '$toolname' in database.\nAvailable tools are: '".join("', '", sort keys(%programs))."'.\n" if ($found eq 'false');
	
	my $pathOfDockerfiles = '/vol/projects/sjanssen/docker_profiling_tools';
	my $resultdir = "/vol/projects/sjanssen/dockerruns";
	my $ncores = 4;

	my $SCRIPT = '#!/bin/bash'."\n\n";
	$SCRIPT .= '#$ -S /usr/bin/bash'."\n";
	$SCRIPT .= '#$ -N '.$toolname.''."\n";
	$SCRIPT .= '#$ -e '.$resultdir.'/ERR/'."\n";
	$SCRIPT .= '#$ -o '.$resultdir.'/OUT/'."\n";
	$SCRIPT .= '#$ -pe multislot '.$ncores."\n";
	$SCRIPT .= '#$ -l virtual_free='.$programs{$toolname}->{ram}.'g'."\n";
	$SCRIPT .= '#$ -l mem_free='.$programs{$toolname}->{ram}.'g'."\n";
	$SCRIPT .= '#$ -cwd'."\n\n";
	$SCRIPT .= 'uname -a'."\n";
	$SCRIPT .= 'cd '.$pathOfDockerfiles."\n";
	$SCRIPT .= 'docker build -f '.$pathOfDockerfiles.'/'.$toolname.'/Dockerfile_'.$toolname.' -t '.$toolname.' .'."\n";
	$SCRIPT .= 'docker run --rm=true --memory='.$programs{$toolname}->{ram}.'g --memory-swap=-1 --cpuset-cpus='.$ncores." \\\n";
	$SCRIPT .= '-v "/vol/projects/sjanssen/CAMI/:/exchange/input"'." \\\n";
	$SCRIPT .= '-v "'.$resultdir.'/'.$toolname.':/exchange/output:rw"'." \\\n";
	$SCRIPT .= '-t '.$toolname."\n";

	return $SCRIPT."\n";
}