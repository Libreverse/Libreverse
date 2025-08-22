#!/usr/bin/env perl
use strict;
use warnings;
use File::Path qw(make_path);
use Cwd        qw(getcwd);

# Simple runner for Libreverse WAF container in detection-only mode with host-mounted audit log.
# Usage: perl scripts/run_waf_det.pl \
#   [--image libreverse:waf-det] [--port 3000] [--logdir ./waf_logs] \
#   [--env KEY=VAL ...] [--env-file path/to/file.env]
# The script will:
#  1. Ensure log directory & audit log file exist on host.
#  2. Collect environment variables from --env and optional --env-file (simple KEY=VAL lines, # comments allowed).
#  3. Run `docker run` mapping the audit log file into the container with the provided env vars.
#  4. Print tail command hint for real-time monitoring.

my %args =
  (image => 'libreverse:waf-det', port => 3000, logdir => "./waf_logs");
my @env_inline;
my @env_files;
while (my $a = shift @ARGV) {
  if ($a eq '--image') {
    $args{image} = shift @ARGV or die "--image requires value";
    next;
  }
  if ($a eq '--port') {
    $args{port} = shift @ARGV or die "--port requires value";
    next;
  }
  if ($a eq '--logdir') {
    $args{logdir} = shift @ARGV or die "--logdir requires value";
    next;
  }
  if ($a eq '--env') {
    my $kv = shift @ARGV or die "--env requires KEY=VAL";
    push @env_inline, $kv;
    next;
  }
  if ($a eq '--env-file') {
    my $f = shift @ARGV or die "--env-file requires path";
    push @env_files, $f;
    next;
  }
  die "Unknown arg: $a";
}

my $cwd        = getcwd();
my $abs_logdir = $args{logdir};
$abs_logdir = "$cwd/$abs_logdir" unless $abs_logdir =~ m{^/};
my $audit_log = "$abs_logdir/modsec_audit.log";

unless (-d $abs_logdir) {
  make_path($abs_logdir) or die "Failed to create $abs_logdir: $!";
}
unless (-e $audit_log) {
  open my $fh, '>', $audit_log or die "Cannot create $audit_log: $!";
  close $fh;
}

my %env_pairs;
for my $kv (@env_inline) {
  my ($k, $v) = split /=/, $kv, 2;
  die "Bad --env format (need KEY=VAL)" unless defined $v && length $k;
  $env_pairs{$k} = $v;
}
for my $file (@env_files) {
  open my $fh, '<', $file or die "Cannot open env file $file: $!";
  while (<$fh>) {
    chomp;
    next if !length || /^\s*#/;
    s/^export\s+//;
    my ($k, $v) = split /=/, $_, 2;
    next unless defined $v;
    $env_pairs{$k} = $v;
  }
  close $fh;
}

print
"Running container with image $args{image} exposing :$args{port} mounting $audit_log\n";

my @cmd = (
  "docker",           "run", "--rm", "--name", "libreverse_waf_det", "-p",
  "$args{port}:3000", "-v",  "$audit_log:/var/log/modsec_audit.log"
);
push @cmd, map { ('-e', "$_=$env_pairs{$_}") } sort keys %env_pairs;
push @cmd, $args{image};

print "+ @cmd\n";
exec @cmd or die "Failed to exec docker run: $!";
