#!/usr/bin/env perl
# Fix haml2slim conversion artifacts in Slim files

use strict;
use warnings;
use File::Find;
use File::Slurp qw(read_file write_file);

my $views_dir = 'app/views';

find(\&fix_file, $views_dir);

sub fix_file {
    return unless /\.slim$/;
    my $file = $File::Find::name;
    
    my $content = read_file($file);
    my $original = $content;
    
    # Fix 1: Remove standalone pipes at end of lines (multiline continuations)
    # These are HAML multiline markers that Slim doesn't use
    $content =~ s/\s+\|\s*$//gm;
    
    # Fix 2: Fix broken hash attributes split across lines
    # Pattern: {"key" => "value",\n" key2" => "value2"}
    # Join lines that start with " (quote after newline from broken hash)
    while ($content =~ s/(\{[^}]*),\n\s*"/" /gs) {
        # Keep looping until no more matches
    }
    
    # Fix 3: Clean up Ruby block pipes in ruby: filter sections
    # In Slim, ruby: blocks don't need | at start of lines
    $content =~ s/^(\s*)ruby:\s*\n((?:\s*\|[^\n]*\n)+)/fix_ruby_block($1, $2)/gme;
    
    # Fix 4: Fix remaining | at start of lines within attribute hashes
    $content =~ s/^\s*\|\s*'/'/gm;
    $content =~ s/^\s*\|\s*"/"/gm;
    
    # Fix 5: Clean up double spaces
    $content =~ s/  +/ /g;
    
    if ($content ne $original) {
        print "Fixed: $file\n";
        write_file($file, $content);
    }
}

sub fix_ruby_block {
    my ($indent, $block) = @_;
    # Remove | from start of lines in ruby blocks
    $block =~ s/^\s*\|[ ]?//gm;
    return "${indent}ruby:\n$block";
}
