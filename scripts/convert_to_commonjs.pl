#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Slurp;
use Getopt::Long;

# Script to convert CoffeeScript files from ES6 import/export to CommonJS require() syntax
# This is needed for eslint-plugin-coffee compatibility

my $dry_run = 0;
my $verbose = 0;
my $help = 0;

GetOptions(
    'dry-run|n' => \$dry_run,
    'verbose|v' => \$verbose,
    'help|h' => \$help
) or die("Error in command line arguments\n");

if ($help) {
    print <<EOF;
Usage: $0 [OPTIONS] [DIRECTORY]

Convert CoffeeScript files from ES6 import/export to CommonJS require() syntax.

Options:
  -n, --dry-run    Show what would be changed without modifying files
  -v, --verbose    Show detailed output
  -h, --help       Show this help message

Example:
  $0 --dry-run app/javascript/controllers/
  $0 --verbose app/javascript/

EOF
    exit 0;
}

my $directory = $ARGV[0] || 'app/javascript';

# Find all .coffee files
my @coffee_files;
find(sub {
    push @coffee_files, $File::Find::name if /\.coffee$/;
}, $directory);

print "Found " . scalar(@coffee_files) . " CoffeeScript files to process\n" if $verbose;

my $files_changed = 0;

foreach my $file (@coffee_files) {
    print "Processing: $file\n" if $verbose;
    
    my $content = read_file($file);
    my $original_content = $content;
    
    # Convert imports
    # Handle star imports: import * as Foo from "module"
    $content =~ s/^import\s+\*\s+as\s+([A-Za-z_][A-Za-z0-9_]*)\s+from\s+["']([^"']+)["']\s*$/$1 = require '$2'/gm;
    
    # Handle named imports: import { foo, bar } from "module"
    $content =~ s/^import\s*\{\s*([^}]+)\s*\}\s*from\s*["']([^"']+)["']\s*$/{ $1 } = require '$2'/gm;
    
    # Handle default imports: import Foo from "module"
    $content =~ s/^import\s+([A-Za-z_][A-Za-z0-9_]*)\s+from\s+["']([^"']+)["']\s*$/$1 = require '$2'/gm;
    
    # Handle mixed imports: import Foo, { bar, baz } from "module"
    $content =~ s/^import\s+([A-Za-z_][A-Za-z0-9_]*)\s*,\s*\{\s*([^}]+)\s*\}\s*from\s*["']([^"']+)["']\s*$/$1 = require '$3'\n{ $2 } = require '$3'/gm;
    
    # Handle multi-line imports - first normalize them
    $content =~ s/^import\s*\{\s*\n((?:\s*[^}]+,?\s*\n)+)\s*\}\s*from\s*["']([^"']+)["']\s*$/process_multiline_import($1, $2)/gme;
    
    # Convert exports
    # Handle named exports: export { foo, bar }
    $content =~ s/^export\s*\{\s*([^}]+)\s*\}\s*$/module.exports = { $1 }/gm;
    
    # Handle default exports: export default Foo
    $content =~ s/^export\s+default\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/module.exports = $1/gm;
    
    # Handle default class exports: export default class Foo extends Bar
    $content =~ s/^export\s+default\s+class\s+([A-Za-z_][A-Za-z0-9_]*)\s+extends\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/class $1 extends $2/gm;
    
    # Handle anonymous default class exports: export default class extends Bar
    $content =~ s/^export\s+default\s+class\s+extends\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/class DefaultExport extends $1/gm;
    
    # Add module.exports for classes that were exported as default
    my $needs_module_exports = 0;
    my $class_name = '';
    
    if ($original_content =~ /export\s+default\s+class\s+([A-Za-z_][A-Za-z0-9_]*)\s+extends/) {
        $class_name = $1;
        $needs_module_exports = 1;
    } elsif ($original_content =~ /export\s+default\s+class\s+extends/ && $content =~ /class\s+DefaultExport\s+extends/) {
        $class_name = 'DefaultExport';
        $needs_module_exports = 1;
    }
    
    if ($needs_module_exports && $content !~ /module\.exports\s*=/) {
        $content .= "\n\nmodule.exports = $class_name\n";
    }
    
    # Clean up spacing
    $content =~ s/\n\n\n+/\n\n/g;
    
    # Check if file was modified
    if ($content ne $original_content) {
        $files_changed++;
        
        if ($dry_run) {
            print "WOULD CHANGE: $file\n";
            print "--- Original ---\n";
            print show_relevant_lines($original_content);
            print "--- Converted ---\n";
            print show_relevant_lines($content);
            print "\n";
        } else {
            write_file($file, $content);
            print "CHANGED: $file\n" if $verbose;
        }
    }
}

print "\n";
if ($dry_run) {
    print "DRY RUN: $files_changed files would be changed\n";
} else {
    print "COMPLETED: $files_changed files were changed\n";
}

sub process_multiline_import {
    my ($imports, $module) = @_;
    
    # Clean up the imports - remove newlines and extra spaces
    $imports =~ s/\n/ /g;
    $imports =~ s/\s+/ /g;
    $imports =~ s/^\s+|\s+$//g;
    
    return "{ $imports } = require '$module'";
}

sub show_relevant_lines {
    my $content = shift;
    my @lines = split /\n/, $content;
    my @relevant_lines;
    
    for my $i (0..$#lines) {
        my $line = $lines[$i];
        if ($line =~ /^(import|export|require|module\.exports)/ || 
            $line =~ /^\s*\{.*\}\s*=\s*require/ ||
            $line =~ /^class\s+\w+\s+extends/) {
            push @relevant_lines, sprintf("%3d: %s", $i+1, $line);
        }
    }
    
    return join("\n", @relevant_lines) . "\n";
}
