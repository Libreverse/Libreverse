#!/usr/bin/env perl

use strict;
use warnings;

print "Installing\n";

my @pids;
my %child_status;

# Run bundle install in background
my $pid1 = fork();
die "Cannot fork: $!" unless defined $pid1;
if ($pid1 == 0) {
    # Child process for bundle install
    print "  Starting bundle install...\n";
    exec("bundle", "install") or die "Cannot exec bundle install: $!";
}
push @pids, $pid1;

# Run bun install in background
my $pid2 = fork();
die "Cannot fork: $!" unless defined $pid2;
if ($pid2 == 0) {
    # Child process for bun install
    print "  Starting bun install...\n";
    exec("bun", "install") or die "Cannot exec bun install: $!";
}
push @pids, $pid2;

# Wait for both processes
my $errors = 0;
foreach my $pid (@pids) {
    waitpid($pid, 0);
    my $exit_code = $? >> 8;
    my $cmd = ($pid == $pid1) ? "bundle install" : "bun install";
    if ($exit_code != 0) {
        print "!!! $cmd failed with exit code $exit_code !!!\n";
        $errors = 1;
    } else {
        print "  Finished $cmd successfully.\n";
    }
}

if ($errors) {
    print "!!! Setup finished with errors !!!\n";
    exit 1;
} else {
    print "Finished installing\n";
    exit 0;
} 