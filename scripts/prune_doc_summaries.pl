#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use Cwd qw(abs_path);

# prune_doc_summaries.pl
# Removes documentation files that are summaries/status logs rather than user-facing feature docs.
#
# Usage:
#   perl scripts/prune_doc_summaries.pl           # dry-run (shows what would be removed)
#   perl scripts/prune_doc_summaries.pl --yes     # actually delete files
#   perl scripts/prune_doc_summaries.pl --yes --git  # use `git rm -f` when inside a git repo
#
# Exit codes: 0 on success, non-zero on errors.

my $do_delete = 0;
my $use_git   = 0;
for my $arg (@ARGV) {
  $do_delete = 1 if $arg eq '--yes' || $arg eq '-y';
  $use_git   = 1 if $arg eq '--git';
}

my $repo_root = abs_path( File::Spec->catdir( $Bin, '..' ) );
die "Unable to resolve repo root from $Bin\n" unless defined $repo_root;

my @files = (
  # CODEQL and project status
  'documentation/CODEQL_CURRENT_STATUS.md',
  'documentation/CODEQL_IGNORE_FILES_UPDATED.md',
  'documentation/CODEQL_MIRRORING_COMPLETE.md',
  'documentation/CODEQL_REPLICATION_PLAN.md',
  'documentation/CODEQL_SETUP_COMPLETE.md',
  'documentation/CODEQL_TEMPORARILY_DISABLED.md',
  'documentation/PHASE_1_2_COMPLETE.md',

  # Summaries and non-actionable change logs
  'documentation/BASEINDEXER_ENHANCEMENT_SUMMARY.md',
  'documentation/DISMISSABLE_GLASS_MIGRATION_SUMMARY.md',
  'documentation/DRAWER_REFACTORING_SUMMARY.md',
  'documentation/GLASS_CLEANUP_SUMMARY.md',
  'documentation/LIQUID_GLASS_MIGRATION_SUMMARY.md',
  'documentation/LITESTREAM_INTEGRATION_SUMMARY.md',
  'documentation/P2P_REMOVAL_AND_CONTROLLER_MERGE_SUMMARY.md',
  'documentation/WEBSOCKET_P2P_IMPLEMENTATION_SUMMARY.md',
  'documentation/ZIP_INTEGRATION_SUMMARY.md',
  'documentation/caching_cleanup_summary.md',
  'documentation/csrf_security_audit_summary.md',
  'documentation/csrf_security_fix_summary.md',
  'documentation/glass_fallback_system_complete.md',
  'documentation/grpc_api_summary.md',
  'documentation/grpc_completion_summary.md',
  'documentation/grpc_implementation_summary.md',
  'documentation/json_api_implementation_summary.md',
  'documentation/stimulus_store_implementation_summary.md',
  'documentation/umami_implementation_summary.md',
  'documentation/webgl_context_fix_summary.md',
  'documentation/websocket_p2p_completion_summary.md',
  'documentation/xmlrpc_api_expansion_summary.md',
  'documentation/graphql_api_implementation_summary.md',
);

my $is_git_repo = _is_git_repo($repo_root);
if ($use_git && !$is_git_repo) {
  warn "--git specified but repository not detected at $repo_root; proceeding without git.\n";
  $use_git = 0;
}

my @existing;
for my $rel (@files) {
  my $abs = File::Spec->catfile($repo_root, $rel);
  push @existing, { rel => $rel, abs => $abs } if -e $abs;
}

if (!@existing) {
  print "No targeted files found. Nothing to do.\n";
  exit 0;
}

print(($do_delete ? 'Deleting' : 'Would delete') . " the following files (" . scalar(@existing) . ")\n\n");
for my $f (@existing) {
  print "  - $f->{rel}\n";
}
print "\n";

if (!$do_delete) {
  print "Dry-run only. Re-run with --yes to perform deletion" . ($use_git ? " using git" : "") . ".\n";
  exit 0;
}

my ($deleted, $failed) = (0, 0);
for my $f (@existing) {
  if ($use_git) {
    my $ok = system('git', '-C', $repo_root, 'rm', '-f', $f->{rel}) == 0;
    if ($ok) { $deleted++ } else { warn "git rm failed for $f->{rel}\n"; $failed++ }
  } else {
    if (unlink $f->{abs}) { $deleted++ } else { warn "unlink failed for $f->{rel}: $!\n"; $failed++ }
  }
}

print "\nDone. Deleted: $deleted. Failed: $failed.\n";
exit ($failed ? 1 : 0);

sub _is_git_repo {
  my ($dir) = @_;
  return system('git', '-C', $dir, 'rev-parse', '--is-inside-work-tree', '>/dev/null', '2>&1') == 0;
}
