#!/usr/bin/perl

use strict;
use warnings;

my @db_paths = (
    "db/libreverse_development.sqlite3",
    "db/libreverse_test.sqlite3"
);

foreach my $db_path (@db_paths) {
    my $journal_file = "${db_path}-journal";
    
    # Find and kill processes using the SQLite DB
    my $pids = `lsof | grep "$db_path" | awk '{print \$2}' | sort | uniq`;
    chomp($pids);
    
    if ($pids) {
        print "Killing processes using $db_path: $pids\n";
        foreach my $pid (split(/\s+/, $pids)) {
            system("kill -9 $pid 2>/dev/null");
        }
    } else {
        print "No processes using $db_path found.\n";
    }
    
    # Remove journal file if it exists
    if (-f $journal_file) {
        print "Removing $journal_file\n";
        unlink($journal_file) or warn "Could not remove $journal_file: $!";
    }
}

print "SQLite unlock complete.\n";
