#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use Cwd qw(getcwd abs_path);

# Scan built bundles for preserved JSDoc type hints:
# Looks for /*! ... */ blocks containing @param { or @returns {
# Usage: perl scripts/check_type_hints.pl [dir]

my $root     = getcwd();
my $scan_dir = $ARGV[0] // 'public';
$scan_dir = abs_path($scan_dir) if -d $scan_dir;

my @files;
find(
  sub {
    return unless -f $_;
    return unless $_ =~ /\.(?:m?js)$/;
    push @files, $File::Find::name;
  },
  $scan_dir
);

my $preserve_re = qr{ /\*! (.*?) \*/ }sx;    # capture comment block bodies
my $has_type    = sub { $_[0] =~ /(\@param\s*\{|\@returns\s*\{)/s };

my $total_blocks = 0;
my $total_type   = 0;
my $total_blocks_with_non_any =
  0;    # blocks that have at least one non-any typed tag
my $total_blocks_only_any = 0;    # blocks that have types but all are any
my $total_tags_non_any =
  0;    # count of individual @param/@returns tags that are non-any
my $total_tags_any = 0;  # count of individual @param/@returns tags that are any
my @reports;

for my $file (@files) {
  open my $fh, '<:encoding(UTF-8)', $file or do {
    warn "[typehints] Failed to read $file: $!\n";
    next;
  };
  local $/;
  my $content = <$fh>;
  close $fh;
  my $blocks      = 0;
  my $type_blocks = 0;
  while ($content =~ /$preserve_re/g) {
    $blocks++;
    my $body = $1 // '';

    # Extract all declared types from @param {TYPE} and @returns {TYPE}
    my @types_found;
    while ($body =~ /\@param\s*\{\s*([^}]+?)\s*\}/sg) {
      push @types_found, lc $1;
    }
    while ($body =~ /\@returns?\s*\{\s*([^}]+?)\s*\}/sg) {
      push @types_found, lc $1;
    }

    if (@types_found) {
      $type_blocks++;
      my $non_any = 0;
      for my $t (@types_found) {
        if   ($t =~ /^\s*any\s*$/i) { $total_tags_any++; }
        else                        { $total_tags_non_any++; $non_any++; }
      }
      if   ($non_any > 0) { $total_blocks_with_non_any++; }
      else                { $total_blocks_only_any++; }
    }
  }
  $total_blocks += $blocks;
  $total_type   += $type_blocks;
  if ($type_blocks > 0) {
    my $rel = $file;
    $rel =~ s/^\Q$root\E\/?//;
    push @reports,
      sprintf(
      '[typehints] \x{2714} %s -> preserved blocks: %d, type blocks: %d',
      $rel, $blocks, $type_blocks);
  }
}

print sprintf("[typehints] Scanned %d JS files under %s\n",
  scalar(@files), ($scan_dir // 'public'));
print $_, "\n" for @reports;

my $total_no_type = $total_blocks - $total_type;

if ($total_type == 0) {
  print
"[typehints] No preserved type hints found (/*! ... \@param\/\@returns ...) in built bundles.\n";
  exit 2;
} else {
  print sprintf("[typehints] Total preserved blocks: %d, with type hints: %d\n",
    $total_blocks, $total_type);
  print sprintf("[typehints] Preserved blocks without type hints: %d\n",
    $total_no_type);
  print sprintf("[typehints] Blocks with non-any type hints: %d\n",
    $total_blocks_with_non_any);
  print sprintf("[typehints] Blocks with only any type hints: %d\n",
    $total_blocks_only_any);
  print sprintf("[typehints] Non-any tags: %d, any tags: %d\n",
    $total_tags_non_any, $total_tags_any);
  exit 0;
}
