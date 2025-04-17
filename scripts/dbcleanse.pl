#!/usr/bin/env perl

use strict;
use warnings;
use File::Copy qw(move);
use File::Path qw(remove_tree make_path);

my $source_dir = './tmp/db';
my $backup_dir = './tmp/db_backup';

print "--- Backing up $source_dir to $backup_dir ---\n";

# Check if source exists before trying to move
if (-d $source_dir) {
    # Remove existing backup first, if it exists
    if (-e $backup_dir) {
        print "Removing existing backup directory: $backup_dir\n";
        remove_tree($backup_dir, { verbose => 0, error => \my $err }) or do {
            warn "Could not remove existing backup $backup_dir: ", join(', ', @$err);
            # Decide if this is fatal
            # exit 1;
        };
    }

    # Use move (rename) for efficiency if possible, might require Copy::Recursive if across filesystems
    # For simplicity matching `cp -r && rm -rf`, we use copy_recursive or simulate it
    # Simulating with move then remove_tree
    eval {
        # Attempt to move (rename) the directory
        move($source_dir, $backup_dir) or die "Failed to move $source_dir to $backup_dir: $!";
        print "Backup created successfully.\n";
    };
    if ($@) {
        warn "Failed to backup $source_dir: $@";
        # Consider adding recursive copy as a fallback if move fails
        exit 1; # Exit if backup failed
    }
} else {
    print "Source directory $source_dir does not exist, nothing to back up.\n";
}

# Remove original directory (should not exist if move succeeded, but check anyway)
if (-d $source_dir) {
    print "--- Removing $source_dir ---\n";
    remove_tree($source_dir, { verbose => 0, error => \my $err }) or do {
        warn "Could not remove $source_dir: ", join(', ', @$err);
        # Decide if this is fatal
        # exit 1;
    };
}

# Recreate the directory
print "--- Creating empty directory $source_dir ---\n";
make_path($source_dir, { verbose => 0, mode => 0777 }) or do {
    warn "Could not create directory $source_dir: $!";
    exit 1; # Exit if creation failed
};

print "--- Database cleanse complete ---\n";
exit 0; 