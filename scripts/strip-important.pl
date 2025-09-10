#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use Getopt::Long;
use File::Spec;
use Encode qw(decode encode);

# Options
my $root        = File::Spec->rel2abs('.');
my $dry_run     = 0;
my $verbose     = 0;
my @include_ext = qw(.scss .css);

GetOptions(
  'root|r=s'   => \$root,
  'dry-run|n!' => \$dry_run,
  'verbose|v+' => \$verbose,
) or die "Usage: $0 [--root PATH] [--dry-run] [--verbose]\n";

$root = File::Spec->rel2abs($root);

my %skip_dirs = map { $_ => 1 } qw(
  .git
  node_modules
  vendor
  vendor/bundle
  log
  tmp
  coverage
  storage
  public/packs
  public/assets
);

my $changed_files = 0;
my $scanned_files = 0;

sub should_skip_dir {
  my ($dir) = @_;
  # Normalize to relative path from root
  my $rel = File::Spec->abs2rel($dir, $root);
  return 0 if $rel =~ m{\.\.(?:/|\\)};    # outside root
  return 1 if exists $skip_dirs{$rel};
  # Skip any path component that matches skip list
  for my $k (keys %skip_dirs) {
    return 1 if $rel =~ m{^\Q$k\E(?:/|\\|$)};
  }
  return 0;
}

sub has_wanted_ext {
  my ($path) = @_;
  for my $ext (@include_ext) {
    return 1 if lc($path) =~ /\Q$ext\E\z/i;
  }
  return 0;
}

sub strip_important_stream {
  my ($s)     = @_;
  my $out     = '';
  my $len     = length $s;
  my $i       = 0;
  my $removed = 0;           # track if we removed any !important

  my $STATE_CODE = 0;
  my $STATE_STR  = 1;
  my $STATE_BCMT = 2;             # /* */
  my $STATE_LCMT = 3;             # // ...\n
  my $state      = $STATE_CODE;
  my $quote      = undef;

  while ($i < $len) {
    my $ch = substr($s, $i, 1);

    if ($state == $STATE_CODE) {
      # Enter string
      if ($ch eq '"' || $ch eq "'") {
        $state = $STATE_STR;
        $quote = $ch;
        $out .= $ch;
        $i++;
        next;
      }
      # Enter block comment
      if ($ch eq '/' && $i + 1 < $len && substr($s, $i + 1, 1) eq '*') {
        $state = $STATE_BCMT;
        $out .= '/*';
        $i += 2;
        next;
      }
      # Enter line comment (SCSS)
      if ($ch eq '/' && $i + 1 < $len && substr($s, $i + 1, 1) eq '/') {
        $state = $STATE_LCMT;
        $out .= '//';
        $i += 2;
        next;
      }
    # Detect and remove !important (with optional whitespace) case-insensitively
      if ($ch eq '!') {
        my $j = $i + 1;
        # Skip whitespace
        while ($j < $len) {
          my $c = substr($s, $j, 1);
          last unless $c =~ /\s/;
          $j++;
        }
        my $remaining = substr($s, $j);
        if ($remaining =~ /^important\b/i) {
          # Remove any trailing part of 'important'
          my $skip = 9;    # length('important')
                           # Advance index to just after the 'important' token
          $i = $j + $skip;
          $removed++;
          next;
        }
      }
      # Default: copy char
      $out .= $ch;
      $i++;
      next;
    }

    if ($state == $STATE_STR) {
      $out .= $ch;
      $i++;
      if ($ch eq '\\' && $i < $len) {    # escape next char
        $out .= substr($s, $i, 1);
        $i++;
        next;
      }
      if ($ch eq $quote) {
        $state = $STATE_CODE;
        $quote = undef;
      }
      next;
    }

    if ($state == $STATE_BCMT) {
      $out .= $ch;
      $i++;
      if ($ch eq '*' && $i < $len && substr($s, $i, 1) eq '/') {
        $out .= '/';
        $i++;
        $state = $STATE_CODE;
      }
      next;
    }

    if ($state == $STATE_LCMT) {
      $out .= $ch;
      $i++;
      if ($ch eq "\n") {
        $state = $STATE_CODE;
      }
      next;
    }
  }

  return ($out, $removed ? 1 : 0);
}

sub process_file {
  my ($path) = @_;
  $scanned_files++;

  open my $fh, '<:raw', $path or do {
    warn "Could not read $path: $!\n" if $verbose;
    return 0;
  };
  local $/;    # slurp
  my $raw = <$fh> // '';
  close $fh;

  # Assume UTF-8 text files (common for CSS/SCSS)
  my $text = eval { decode('UTF-8', $raw, 1) };
  $text = $raw unless defined $text;    # fall back if not UTF-8

  my ($processed, $modified) = strip_important_stream($text);

  if ($modified) {
    if ($dry_run) {
      print "Would modify: $path\n" if $verbose;
      return 1;
    } else {
      open my $outfh, '>:raw', $path or do {
        warn "Could not write $path: $!\n";
        return 0;
      };
      my $enc = eval { encode('UTF-8', $processed, 1) };
      $enc = $processed unless defined $enc;
      print {$outfh} $enc;
      close $outfh;
      print "Modified: $path\n" if $verbose;
      return 1;
    }
  }
  return 0;
}

find({
    wanted => sub {
      return if -d $_;
      my $path = $File::Find::name;
      # Skip directories in our skip list
      if ($File::Find::dir && should_skip_dir($File::Find::dir)) {
        $File::Find::prune = 1;
        return;
      }
      return unless has_wanted_ext($path);
      $changed_files += process_file($path);
    },
    no_chdir => 1,
  },
  $root
);

print sprintf(
  "Scanned %d files. %s %d file(s).\n",
  $scanned_files, ($dry_run ? 'Would modify' : 'Modified'),
  $changed_files,
);

exit 0;
