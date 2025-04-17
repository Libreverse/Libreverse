#!/usr/bin/env perl

use strict;
use warnings;

# Helper function to run a command and check status
sub run_docker_command {
    my (@cmd) = @_;
    print "--- Running: @cmd ---\n";
    my $exit_code = system(@cmd);

    # Check system() return value first for execution errors
    if ($exit_code == -1) {
        print "!!! Failed to execute command '@cmd': $! !!!\n";
        return 1; # Indicate failure
    }

    # Check the actual exit status of the command
    my $actual_exit_code = $? >> 8;
    if ($actual_exit_code != 0) {
        # Docker commands often print errors to stderr, which system() doesn't capture directly
        # We just note the failure code here.
        print "!!! Command '@cmd' failed with exit code $actual_exit_code !!!\n";
        # Don't necessarily exit, try the next command (matching bash behavior)
    } else {
        print "--- Command '@cmd' completed successfully ---\n";
    }
    print "\n";
    return $actual_exit_code;
}

# Get all container IDs (running and stopped)
print "--- Getting container IDs ---\n";
my @container_ids = map { chomp; $_ } qx(docker ps -aq);

if (@container_ids) {
    # Stop containers
    run_docker_command("docker", "stop", @container_ids);

    # Remove containers
    run_docker_command("docker", "rm", @container_ids);
} else {
    print "No containers found to stop or remove.\n\n";
}

# Get all image IDs
print "--- Getting image IDs ---\n";
my @image_ids = map { chomp; $_ } qx(docker images -aq);

if (@image_ids) {
    # Remove images forcefully
    run_docker_command("docker", "rmi", "-f", @image_ids);
} else {
    print "No images found to remove.\n\n";
}

print "--- Docker nuke attempt finished ---";
# The original script didn't have an explicit exit code.
# We exit 0, but failures will have been printed.
exit 0; 