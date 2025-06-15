#!/usr/bin/env perl

use strict;
use warnings;

print "Installing\n";

# Helper to check if a command exists
sub command_exists {
    my ($cmd) = @_;
    return system("command -v $cmd >/dev/null 2>&1") == 0;
}

# Install Ruby if not present
unless (command_exists('ruby')) {
    print "  Ruby not found. Installing Ruby (via Homebrew)...\n";
    system("brew install ruby") == 0 or die "Failed to install Ruby";
} else {
    print "  Ruby is already installed.\n";
}

# Install Node if not present
unless (command_exists('node')) {
    print "  Node.js not found. Installing Node.js (via Homebrew)...\n";
    system("brew install node") == 0 or die "Failed to install Node.js";
} else {
    print "  Node.js is already installed.\n";
}

# Install Bun if not present
unless (command_exists('bun')) {
    print "  Bun not found. Installing Bun (via install script)...\n";
    system("curl -fsSL https://bun.sh/install | bash") == 0 or die "Failed to install Bun";
    # Add Bun to PATH for this session if installed in ~/.bun
    $ENV{PATH} = "$ENV{HOME}/.bun/bin:$ENV{PATH}";
} else {
    print "  Bun is already installed.\n";
}

my @pids;
my %child_status;

# Run bundle install in background
my $pid1 = fork();
die "Cannot fork: $!" unless defined $pid1;
if ($pid1 == 0) {
    print "  Starting bundle install...\n";
    exec("bundle", "install") or die "Cannot exec bundle install: $!";
}
push @pids, $pid1;

# Run bun install in background
my $pid2 = fork();
die "Cannot fork: $!" unless defined $pid2;
if ($pid2 == 0) {
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