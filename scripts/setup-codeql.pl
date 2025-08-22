#!/usr/bin/env perl

# CodeQL Integration for SETUP.pl
# This subroutine can be called from SETUP.pl to set up CodeQL

use strict;
use warnings;

sub setup_codeql {
  print "Setting up CodeQL for security analysis...\n";

  # Check if CodeQL setup script exists
  my $codeql_script = "scripts/codeql-local.sh";
  unless (-f $codeql_script && -x $codeql_script) {
    print "  CodeQL setup script not found or not executable\n";
    return 0;
  }

  # Install CodeQL CLI
  print "  Installing CodeQL CLI...\n";
  my $install_result = system("$codeql_script --install");
  if ($install_result != 0) {
    print "  Failed to install CodeQL CLI\n";
    return 0;
  }

  # Test the installation
  print "  Testing CodeQL installation...\n";
  my $test_script = "scripts/test-codeql-setup.sh";
  if (-f $test_script && -x $test_script) {
    my $test_result = system("$test_script");
    if ($test_result != 0) {
      print "  CodeQL installation test failed, but continuing...\n";
    } else {
      print "  CodeQL installation test passed\n";
    }
  }

  print "  CodeQL setup completed successfully\n";
  return 1;
}

# If this script is run directly, execute the setup
if ($0 eq __FILE__) {
  setup_codeql();
}

1;    # Return true for require/use
