#!/usr/bin/env perl

use strict;
use warnings;

# Function to run a script and check its exit status
sub run_script {
    my ($script_path) = @_;
    print "--- Running $script_path ---\n";
    my $exit_code = system($script_path);

    if ($exit_code == -1) {
        print "!!! Failed to execute $script_path: $! !!!\n";
        # Decide if script should exit immediately on failure to execute
        # exit 1; 
    } elsif ($? & 127) {
        # Signalled
        printf "!!! $script_path was killed by signal %d !!!\n", ($? & 127);
        # exit 1;
    } elsif ($? >> 8 != 0) {
        # Exited with non-zero status
        printf "!!! $script_path failed with exit code %d !!!\n", $? >> 8;
        # exit 1;
    } else {
        print "--- $script_path completed successfully ---\n";
    }
    print "\n"; # Add spacing
    # Return the actual exit code (0 for success)
    return $? >> 8;
}

my @scripts_to_run = (
    "perl ./scripts/dockernuke.pl",
    "perl ./scripts/dbcleanse.pl",
    "perl ./scripts/build.pl",
);

my $overall_failure = 0;

foreach my $script (@scripts_to_run) {
    my $script_exit_code = run_script($script);
    if ($script_exit_code != 0) {
        $overall_failure = 1;
        # Optional: uncomment below to stop on first failure
        # last;
    }
}

if ($overall_failure) {
    print "One or more scripts failed.\n";
    exit 1; # Exit with non-zero status if any script failed
} else {
    print "All scripts completed successfully.\n";
    exit 0;
} 