#!/usr/bin/env perl

use strict;
use warnings;

# Wait until rails-db-creator is done
until (-f '/tmp/.db_creator_done.txt') {
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
