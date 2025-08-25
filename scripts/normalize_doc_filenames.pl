#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use File::Basename qw(basename dirname);
use Cwd qw(abs_path);
use Encode;

# normalize_doc_filenames.pl
# - Renames files under documentation/ to lowercase-kebab-case
# - Updates internal links in markdown files to the new names
#
# Usage:
#   perl scripts/normalize_doc_filenames.pl           # dry-run
#   perl scripts/normalize_doc_filenames.pl --yes     # apply
#   perl scripts/normalize_doc_filenames.pl --yes --git  # apply using git mv

my $do_apply = 0;
my $use_git  = 0;
for my $arg (@ARGV) {
  $do_apply = 1 if $arg eq '--yes' || $arg eq '-y';
  $use_git  = 1 if $arg eq '--git';
}

my $repo_root = abs_path(File::Spec->catdir($Bin, '..'));
my $docs_dir  = File::Spec->catdir($repo_root, 'documentation');
die "documentation directory not found at $docs_dir\n" unless -d $docs_dir;

sub is_git_repo {
  return system('git', '-C', $repo_root, 'rev-parse', '--is-inside-work-tree', '>/dev/null', '2>&1') == 0;
}
if ($use_git && !is_git_repo()) {
  warn "--git specified but repository not detected; proceeding without git.\n";
  $use_git = 0;
}

# Collect files
opendir(my $dh, $docs_dir) or die "Cannot open $docs_dir: $!\n";
my @entries = grep { !/^\./ } readdir($dh);
closedir $dh;

my %map;         # old_rel => new_rel
my %new_to_old;  # new_rel => old_rel (to detect collisions)

sub kebab {
  my ($name) = @_;
  my ($stem, $ext) = $name =~ /^(.*?)(\.[^.]+)?$/;
  $ext //= '';
  $stem = lc $stem;
  $stem =~ s/[ _]+/-/g;             # spaces/underscores -> hyphen
  $stem =~ s/[^a-z0-9\.-]+/-/g;    # non alnum/dot -> hyphen
  $stem =~ s/\.+/-/g;              # dots inside stem -> hyphen
  $stem =~ s/-{2,}/-/g;             # collapse hyphens
  $stem =~ s/^-|-$//g;              # trim hyphens
  $ext = lc $ext;                   # lower ext
  return $stem . $ext;
}

# Build mapping for top-level files only (no subdirs assumed)
for my $e (@entries) {
  my $old_rel = File::Spec->catfile('documentation', $e);
  my $new_name = kebab($e);
  my $new_rel = File::Spec->catfile('documentation', $new_name);
  next if $old_rel eq $new_rel; # already normalized
  # Resolve collisions by appending numeric suffix
  my $base = $new_name;
  my ($stem, $ext) = $new_name =~ /^(.*?)(\.[^.]+)?$/; $ext //= '';
  my $i = 1;
  while (exists $new_to_old{$new_rel} || -e File::Spec->catfile($repo_root, $new_rel)) {
    $new_name = sprintf('%s-%d%s', $stem, $i++, $ext);
    $new_rel = File::Spec->catfile('documentation', $new_name);
  }
  $map{$old_rel} = $new_rel;
  $new_to_old{$new_rel} = $old_rel;
}

if (!%map) {
  print "All documentation filenames already normalized.\n";
  exit 0;
}

print ($do_apply ? "Renaming" : "Would rename"), " the following files (", scalar(keys %map), "):\n\n";
for my $old (sort keys %map) {
  my $new = $map{$old};
  print "  - $old => $new\n";
}
print "\n";

unless ($do_apply) {
  print "Dry-run only. Re-run with --yes to apply" . ($use_git ? " using git mv" : "") . ".\n";
  exit 0;
}

# Apply renames
my ($ok, $fail) = (0, 0);
for my $old (sort keys %map) {
  my $new = $map{$old};
  my $old_abs = File::Spec->catfile($repo_root, $old);
  my $new_abs = File::Spec->catfile($repo_root, $new);
  if ($use_git) {
    my $ret = system('git', '-C', $repo_root, 'mv', $old, $new);
    if ($ret == 0) { $ok++ } else { warn "git mv failed: $old -> $new\n"; $fail++ }
  } else {
    # Ensure target doesn't exist and parent dir exists
    my $new_dir = dirname($new_abs);
    unless (-d $new_dir) { mkdir $new_dir or die "mkdir $new_dir: $!\n" }
    if (rename $old_abs, $new_abs) { $ok++ } else { warn "rename failed: $old -> $new ($!)\n"; $fail++ }
  }
}

# Update links in .md files inside documentation
opendir($dh, $docs_dir) or die "Cannot reopen $docs_dir: $!\n";
my @md = grep { /\.md$/i } map { File::Spec->catfile($docs_dir, $_) } grep { !/^\./ } readdir($dh);
closedir $dh;

my %short_map; # basename -> basename
for my $old (keys %map) {
  my $new = $map{$old};
  $short_map{basename($old)} = basename($new);
}

for my $path (@md) {
  open my $fh, '<:encoding(UTF-8)', $path or die "read $path: $!\n";
  local $/; my $content = <$fh>; close $fh;
  my $orig = $content;
  for my $old_base (sort { length($b) <=> length($a) } keys %short_map) {
    my $new_base = $short_map{$old_base};
    # Replace markdown links: (old_base) or (./old_base) optionally with anchors
    $content =~ s{\((?:\./)?\Q$old_base\E(#[^)]+)?\)}{($new_base$1)}g;
  }
  next if $content eq $orig;
  open my $out, '>:encoding(UTF-8)', $path or die "write $path: $!\n";
  print $out $content; close $out;
}

print "\nDone. Renamed: $ok. Failed: $fail. Links updated in markdown files.\n";
exit ($fail ? 1 : 0);
