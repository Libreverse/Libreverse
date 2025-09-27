#!/usr/bin/env perl

use strict;
use warnings;

# Get the highest numeric suffix from /tmp/.db_creator_done*.txt files
sub get_highest_number {
  my @files   = glob('/tmp/.db_creator_done*.txt');
  my $highest = -1;    # Default to -1 if no files exist
  for my $file (@files) {
    if ($file =~ /\/tmp\/\.db_creator_done(_(\d+))?\.txt$/) {
      my $num = defined $2 ? $2 : 0;    # Base file (.db_creator_done.txt) is 0
      $highest = $num if $num > $highest;
    }
  }
  return $highest;
}

# Wait until a new /tmp/.db_creator_done*.txt file with a higher number appears
my $last_number = get_highest_number();
while (1) {
  my $current_number = get_highest_number();
  last if $current_number > $last_number;    # New file with higher number found
  sleep 1;
}

# Parse arguments for env vars and build command
my @command;
for my $arg (@ARGV) {
  if ($arg =~ /^[A-Z_]+=.+/) {
    my ($key, $value) = split('=', $arg, 2);
    $ENV{$key} = $value;
  } else {
    push @command, $arg;
  }
}

# Execute the command
exec @command;
