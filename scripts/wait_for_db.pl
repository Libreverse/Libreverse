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

# Wait until a new /tmp/.db_creator_done*.txt file with a higher number appears, then wait for it to be deleted
my $last_number = get_highest_number();
my $target_file;
while (1) {
  my $current_number = get_highest_number();
  if ($current_number > $last_number) {
    # Found new file
    $target_file = $current_number == 0 ? '/tmp/.db_creator_done.txt' : "/tmp/.db_creator_done_${current_number}.txt";
    last;
  }
  sleep 1;
}

# Now wait for the file to be deleted
while (-f $target_file) {
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
