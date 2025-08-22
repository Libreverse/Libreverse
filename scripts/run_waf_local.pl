#!/usr/bin/env perl
use strict;use warnings;

# Convenience wrapper to launch the WAF/rails container against a local TiDB (passwordless)
# without needing a .env file. Adjust values inline or pass overrides as VAR=VAL args.
#
# Usage:
#   perl scripts/run_waf_local.pl                 # uses defaults below
#   perl scripts/run_waf_local.pl FORCE_SSL=false RAILS_LOG_LEVEL=debug
#   perl scripts/run_waf_local.pl ALLOWED_HOSTS=example.test
#
# Delegates to run_waf_det.pl adding --env parameters.

my %defaults=(
  ALLOWED_HOSTS => 'libreverse-main.geor.me,localhost',
  CORS_ORIGINS  => 'https://libreverse-main.geor.me,http://localhost:3000',
  EEA_MODE      => 'true',
  FORCE_SSL     => 'true',
  RAILS_LOG_LEVEL => 'info',
  DB_SSL_DISABLE => 'true', # disable SSL for local passwordless TiDB
  # RAILS_MASTER_KEY intentionally omitted: image may already have master.key mounted; pass explicitly if needed.
  # Provide empty TiDB creds for passwordless local instance
  TIDB_HOST     => 'host.docker.internal',
  TIDB_USERNAME => '',
  TIDB_PASSWORD => '',
);

# Override defaults with KEY=VAL args
for my $arg(@ARGV){
  my ($k,$v)=split /=/,$arg,2; die "Bad override '$arg' (need KEY=VAL)" unless defined $v; $defaults{$k}=$v;
}

my @env_pairs;
for my $k (sort keys %defaults){
  next if $defaults{$k} eq '' && $k =~ /PASSWORD|USERNAME/; # skip empty auth vars
  push @env_pairs, '--env', "$k=$defaults{$k}";
}

my @cmd=( 'perl','scripts/run_waf_det.pl', '--image','libreverse:waf-det', '--port','3000', '--logdir','./waf_logs', @env_pairs );
print "+ @cmd\n";
exec @cmd or die "Failed to exec run_waf_det.pl: $!";
