#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my ($inputfile) = @ARGV;
parseYAML($inputfile);

sub parseYAML {
	my ($input) = @_;
	
	open (IN, $input) || die "cannot read yaml file '$input': $!";
		#split into documents
		my @documents = ();
		my @doc = ();
		while (my $line = <IN>) {
			chomp $line;
			if (($line =~ m/^---/) || ($line =~ m/^\.\.\./)) {
				if (@doc > 0) {
					my @h = @doc;
					push @documents, \@h;
					@doc = ();
				}
			} else {
				push @doc, $line;
			}
		}
		if (@doc > 0) {
			my @h = @doc;
			push @documents, \@h;
			@doc = ();
		}		
	close (IN);
	
	foreach my $document (@documents) {
		#~ $document = splitIntoNodes($document);
		$document = parse3($document);
	}
	
	return \@documents;
}

sub parse3 {
	my ($lines, $indent) = @_;
	$indent = -1 if (not defined $indent);
	
	my @stack = ();
	foreach my $line (@{$lines}) {
		next if ($line =~ m/^\s*$/);
		my ($line_indent, $rest) = ($line =~ m/^([\s|\-]*)(.+?)$/);
		$line_indent = length($line_indent);
		my ($key, $value) = ($rest =~ m/^(\S+)\s*:\s*(.*?)$/);
		
		if ($line_indent > $indent) {
			print STDERR "push: $line\n";
			if (defined $key) {
				push @stack, {
					$key => {value => $value}, 
					'#indent' => $line_indent,
					'#lastKey' => $key,
				};
			} else {
				$stack[$#stack]->{$stack[$#stack]->{'#lastKey'}}->{value} .= $rest;
			}
		} elsif ($line_indent == $indent) {
			print STDERR "equa: $line\n";
			if (defined $key) {
				$stack[$#stack]->{$key} = {value => $value};
				$stack[$#stack]->{'#indent'} = $line_indent;
				$stack[$#stack]->{'#lastKey'} = $key;
			} else {
				$stack[$#stack]->{$stack[$#stack]->{'#lastKey'}}->{value} .= "\n".$rest;
			}
		} else {
			print STDERR "pull: $line\n";
			for (my $i = @stack-1; $i >= 1; $i--) {
				if ($stack[$i]->{'#indent'} > $line_indent) {
					foreach my $key (keys(%{$stack[$i]})) {
						next if ($key =~ m/^#/);
						$stack[$i-1]->{$stack[$i-1]->{'#lastKey'}}->{children}->{$key} = $stack[$i]->{$key};
					}
					pop @stack;
				}
			}
			if (defined $key) {
				$stack[$#stack]->{$key} = {value => $value};
				$stack[$#stack]->{'#lastKey'} = $key;
			}
		}
		$indent = $line_indent;
	}
	
	print Dumper \@stack;
	die;
}

sub parse {
	my ($lines, $indent) = @_;
	$indent = 0 if (not defined $indent);
	
	my @indents = ();
	foreach my $line (@{$lines}) {
		if ($line =~ m/^\s*$/) {
			push @indents, -1;
		} else {
			my ($line_indent, $rest) = ($line =~ m/^([\s|\-]*)(.+?)$/);
			push @indents, length($line_indent);
		}
	}

	my @blocks = ();
	my @currentBlock = ();
	for (my $i = 0; $i+1 < @{$lines}; $i++) {
		next if ($lines->[$i] =~ m/^\s*$/);
		
		push @currentBlock, $lines->[$i];
		if ($indents[$i+1] == $indent) {
			my @help = @currentBlock;
			push @blocks, \@help;
			@currentBlock = ();
		}
	}
	push @blocks, \@currentBlock if (@currentBlock > 0);
print Dumper "blocks", \@blocks; 
#~ die;	

	foreach my $block (@blocks) {
		if (@{$block} > 1) {
			#~ my $header = shift (@{$block});
			#~ my ($block_indent, $key, $value) = ($header =~ m/^([\s|\-]*)(.+?)\s*:\s*(.*?)$/);
			#~ my @subblocks = @{parse($block, length($block_indent))};
			#~ print Dumper \@subblocks; die;
			#~ $block = [$header, \@subblocks];
		} else {
			
		}
	}
	#~ foreach my $block (@blocks) {
		#~ if (@{$block} > 1) {
			#~ if ($block->[1] !~ m/([\s|\-]*).+?\s*:\s*.*?$/) {
				#~ my $head = shift @{$block};
				#~ my $body = "";
				#~ foreach my $line (@{$block}) {
					#~ $line =~ s/^\s+//;
					#~ chomp $line;
					#~ $body .= "\n" if ($body ne '');
					#~ $body .= $line;
				#~ }
				#~ $block = {head => $head, body => $body};
			#~ } else {
				#~ my ($block_indent, $key, $value) = ($block->[0] =~ m/([\s|\-]*)(.+?)\s*:\s*(.*?)$/);
				#~ my %help = ();
				#~ $help{head} = $key;
				#~ $help{tag} = $value if (defined $value && $value ne '');
				#~ shift @{$block};
				#~ $help{body} = parse($block, length($block_indent));
				#~ $block = \%help;
			#~ }
		#~ } else {
			#~ $block = {head => $block};
		#~ }
	#~ }
	
	
#~ print Dumper "blocks: ", \@blocks;
#~ die;
	#~ foreach my $block (@blocks) {
		#~ my %res = ();
		#~ if ($block->[0] =~ m/([\s|\-]*)(.+?)\s*:\s*(.*?)$/) {
			#~ my ($line_indent, $key, $value) = ($1,$2,$3);
			#~ $res{'key'} = $key;
			#~ if (@{$block} > 1) {
				#~ shift @{$block};
				#~ my ($block_indent) = ($block->[0] =~ m/([\s|\-]*).+?\s*:\s*.*?$/);
				#~ $res{'content'} = parse($block, length($block_indent));
				#~ $res{'tag'} = $value if ($value ne '');
			#~ } else {
				#~ $res{'value'} = $value;
			#~ }
		#~ }
		#~ $block = \%res;
	#~ }
	
	return \@blocks;
}


my $reccount = 0;
sub splitIntoNodes {
	$reccount++;
	die if ($reccount > 20);
	my ($lines, $indent) = @_;

	my %result = ();
	$indent = "" if (not defined $indent);
	my @newNode = ();
	my $newNode_key = undef;
	my $newNode_indent = undef;
	my $newNode_tag = undef;
	
	if ($lines->[0] =~ m/^($indent\-\s*)\S+/) {
		#if it is a listing
		my $listElementStart = $1;
		my @list = ();
		my @listElement = ();
		foreach my $line (@{$lines}) {
			if ($line =~ m/^$listElementStart/) {
				my @help = @listElement;
				push @list, \@help if (@help > 0);
				@listElement = ();
				$line =~ s/^$indent\-(\s*)/$indent $1/;
			}
			push @listElement, $line;
		}
		push @list, \@listElement if (@listElement > 0);

		$listElementStart =~ s/^(\s*)\-/$1 /;
		foreach my $element (@list) {
			$element = splitIntoNodes($element, $listElementStart);
		}
		
		return \@list;
	} else {
		my $blockContent = "";
		for (my $i = 0; $i < @{$lines}; $i++) {
			next if ($lines->[$i] =~ m/^\s*$/); #skip empty lines
			
			my ($line_indent, $line_key, $line_value) = ($lines->[$i] =~ m/^$indent(\s*)(.+?)\s*:\s*(.*?)$/);
			if (not defined $line_indent && not defined $line_key && not defined $line_value) {
				my ($block_indent, $content) = ($lines->[$i] =~ m/^(\s+)(.+?)$/);
				if (@newNode > 0) {
					push @newNode, $lines->[$i];
				} else {
					$blockContent .= "\n" if ($blockContent ne '');
					$blockContent .= $content;
				}
			} else {
				if ($line_indent eq '') {
					if (($line_value ne '') && (($i+1 < @{$lines}) && (length(getIndent($lines->[$i+1])) <= length($indent)))) {
						#leaf
						$result{$line_key} = $line_value;
					} else {
						if (($line_value ne '') && ($i+1 < @{$lines}) && (length(getIndent($lines->[$i+1])) > length($indent))) { 
							$newNode_tag = $line_value;
						}
						if (@newNode > 0) {
							$result{$newNode_key} = splitIntoNodes(\@newNode, $indent.$newNode_indent);
						} elsif ($blockContent ne '') {
							$result{$newNode_key} = $blockContent;
							$result{'#TAG'} = $newNode_tag if (defined $newNode_tag);
							$newNode_tag = undef;
							$blockContent = '';
						}
						$newNode_key = $line_key;
						@newNode = ();
					}
				} else {
					($newNode_indent) = ($lines->[$i] =~ m/^$indent(\s+)(.+)$/) if (@newNode == 0);
					push @newNode, $lines->[$i];
				}
			}
		}
		
		if (@newNode > 0) {
			$result{$newNode_key} = splitIntoNodes(\@newNode, $indent.$newNode_indent);
		} elsif ($blockContent ne '') {
			#~ $newNode_key = '#TAG' if ($newNode_key eq 'TAG');
			$result{$newNode_key} = $blockContent;
			$result{'#TAG'} = $newNode_tag if (defined $newNode_tag);
			$newNode_tag = undef;
			$blockContent = '';
		}
		
		return \%result;
	}
}

sub getIndent {
	my ($line) = @_;
	my ($indent) = ($line =~ m/^(\s*)\S*.*$/);
	return $indent;
}