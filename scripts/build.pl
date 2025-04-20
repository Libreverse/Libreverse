#!/usr/bin/env perl

use strict;
use warnings;

# Function to run a command and exit if it fails
sub run_or_die {
    my (@cmd) = @_;
    print "--- Running: @cmd ---\n";
    system(@cmd);

    if ($? == -1) {
        die "!!! Failed to execute command '@cmd': $! !!!\n";
    } elsif ($? & 127) {
        die sprintf("!!! Command '@cmd' killed by signal %d !!!\n", ($? & 127));
    } elsif ($? >> 8 != 0) {
        die sprintf("!!! Command '@cmd' failed with exit code %d !!!\n", $? >> 8);
    } else {
        print "--- Command '@cmd' completed successfully ---\n";
    }
    print "\n";
}

# Synthesize the Dockerfile
# run_or_die("bin/rails", "generate", "dockerfile", "--force");

# Run docker build
run_or_die("docker", "build", "--platform", "linux/amd64", "-t", "libreverse:alpha", ".");

print "--- Build script finished ---
";
exit 0; 