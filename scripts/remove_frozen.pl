#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;

# Root directory of the project
my $root = '/Users/george/libreverse';

# Find and process .rb files, excluding gem directories
find(\&process_file, $root);

sub process_file {
  # Skip directories
  return if -d $File::Find::name;

  # Only process .rb files
  return unless /\.rb$/;

  # Exclude gem-related directories (e.g., vendor/bundle, .bundle)
  return if $File::Find::name =~ m{/vendor/};
  return if $File::Find::name =~ m{/\.bundle/};
  return if $File::Find::name =~ m{/node_modules/};

  # Read the file
  open my $fh, '<', $_ or die "Can't open $_: $!";
  my @lines = <$fh>;
  close $fh;

  # Remove any lines that are frozen string literal comments
  @lines = grep { !/^\s*# frozen_string_literal:\s*true\s*$/ } @lines;

  # Write the modified content back to the file
  open my $out, '>', $_ or die "Can't write $_: $!";
  print $out @lines;
  close $out;

  print "Processed: $File::Find::name\n";
}
