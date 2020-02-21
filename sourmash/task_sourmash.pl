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
    "sourmash compute --scaled 10000 -k 51 --track-abundance --name-from-first -o ".$task->{resultfilename}.".sig ".$task->{inputfile},
    "sourmash gather --scaled 10000 -k 51 --output ".$task->{resultfilename}.".csv ".$task->{resultfilename}.".sig ".$task->{databaseDir}."/genbank-k51.lca.json.gz",
    "rm ".$task->{resultfilename}.".sig",
    $ENV{PREFIX}."/bin/convert.py --opal_csv ".$task->{resultfilename}.".profile".
    " --taxdump_path ".$task->{taxonomyDir}.
    " --acc2taxid_files ".$task->{databaseDir}."/nucl_gb.accession2taxid.gz ".
    " --acc2taxid_files ".$task->{databaseDir}."/nucl_wgs.accession2taxid.gz ".
    $task->{resultfilename}.".csv",
  );
}

Utils::executeTasks(\@tasks);
