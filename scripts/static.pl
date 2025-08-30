#!/usr/bin/env perl

use strict;
use warnings;
use File::Temp qw(tempfile tempdir);
use File::Path qw(remove_tree);
use File::Copy qw(copy);
use Cwd        qw(abs_path);
use IPC::Open3;
use Symbol qw(gensym);

# Arrays to store status for the (now removed) summary
# We keep them to track status internally if needed later, but don't display summary
my @sequential_status;
my @sequential_tools;
my @parallel_tools;
my @tool_log_files;
my @tool_exit_codes;
my @parallel_status;
my @pids;

print "Running static analysis tasks...\n";

# --- Sequential Tasks --- Function to run and check command
sub run_command {
  my ($tool_name, @cmd) = @_;
  my $status = "[OK]";
  my @output;
  my $exit_code = 0;    # Default to success

  push @sequential_tools, $tool_name;

  # Use IPC::Open3 to capture STDOUT and STDERR separately
  my $stdout_fh = gensym;    # Create anonymous filehandles
  my $stderr_fh = gensym;
  # We don't need to write to child's STDIN
  my $child_pid = open3(undef, $stdout_fh, $stderr_fh, @cmd);

  unless ($child_pid) {
    warn "Failed to execute $tool_name: $!\n";
    print "$tool_name [NOTOK] (Execution failed)\n";
    push @sequential_status, "[NOTOK]";
    return;
  }

  # Read output from both handles
  # This simple read assumes output is not excessively large and won't deadlock
  # More complex scenarios might require non-blocking reads or select()
  my $stdout_content = do { local $/; <$stdout_fh> };
  my $stderr_content = do { local $/; <$stderr_fh> };
  push @output, $stdout_content if defined $stdout_content;
  push @output, $stderr_content if defined $stderr_content;

  # Wait for the child process and get exit status
  waitpid($child_pid, 0);
  $exit_code = $? >> 8;

  if ($exit_code != 0) {
    print "$tool_name [NOTOK] (Exit Code: $exit_code)\n";
    # Only print output if there was any captured
    if (@output) {
      print "--- Output for $tool_name ---\n";
      print @output;    # Print combined STDOUT and STDERR
                        # Ensure newline if output doesn't end with one
      print "\n" unless $output[-1] =~ /\n$/;
      print "--- End Output for $tool_name ---\n";
    }
    $status = "[NOTOK]";
  } else {
    print "$tool_name [OK]\n";
    $status = "[OK]";
  }
  push @sequential_status, $status;
}

# Run Prettier first
my $prettier_tool_name = "Prettier";
push @sequential_tools, $prettier_tool_name;
my $prettier_status = "[OK]";
my ($prettier_fh, $prettier_output_log) = tempfile(UNLINK => 1);  # Auto-cleanup

my $prettier_cmd = ["bun", "prettier", "--write", "."];
my $prettier_exit_code;
my @prettier_raw_output;

# Set timeout using Perl's alarm (basic timeout)
local $SIG{ALRM} = sub { die "Prettier timeout\n" };
alarm(30);    # 30 second timeout
eval {
  open(my $prettier_out_fh, "-|", @$prettier_cmd)
    or die "Failed to run Prettier: $!";
  @prettier_raw_output = <$prettier_out_fh>;
  close $prettier_out_fh;
  $prettier_exit_code = $? >> 8;
};
alarm(0);     # Cancel alarm

if ($@) {    # Check if eval died (e.g., timeout or execution failure)
  warn "$@";
  $prettier_exit_code = 1;    # Mark as failed
}

# Filter output
my @prettier_filtered_output = grep { !/unchanged/ } @prettier_raw_output;

if ($prettier_exit_code != 0) {
  print "$prettier_tool_name [NOTOK] (Exit Code: $prettier_exit_code)\n";
  if (@prettier_filtered_output) {
    print "--- Output for $prettier_tool_name ---\n";
    print @prettier_filtered_output;
    print "--- End Output for $prettier_tool_name ---\n";
  }
  $prettier_status = "[NOTOK]";
} else {
  print "$prettier_tool_name [OK]\n";
  $prettier_status = "[OK]";
}
push @sequential_status, $prettier_status;

# Run other sequential commands
run_command("Rubocop", "bundle", "exec", "rubocop", "-A");
run_command("HAML Whitespace Cleanup", "sh", "-c",
"find . -name '*.haml' -not -path './node_modules/*' -not -path './.git/*' -exec sed -i '' 's/[[:space:]]*\$//' {} +"
);
run_command("haml-lint", "bundle", "exec", "haml-lint", "--auto-correct", ".");

# New: ERB formatting and linting (guarded)
run_command("ERB Format", "sh", "-c",
"command -v bundle >/dev/null && bundle exec erb-format --help >/dev/null 2>&1 && find app -name '*.erb' -not -path 'app/views/layouts/mailer.html.erb' -print0 | xargs -0 -r bundle exec erb-format --write || true"
);
run_command("ERB Lint", "sh", "-c",
"command -v bundle >/dev/null && bundle exec erblint --version >/dev/null 2>&1 && bundle exec erblint --config .erb-lint.yml app/views || true"
);

# Perl formatting (perltidy) — required (fail if missing)
run_command(
  "Perltidy",
  "sh",
  "-c",
q{if find . -type f \( -name '*.pl' -o -name '*.pm' -o -name '*.t' -o -name '*.psgi' \) \
                        -not -path './vendor/*' -not -path './node_modules/*' -not -path './.git/*' -print -quit | grep -q .; then
                    find . -type f \( -name '*.pl' -o -name '*.pm' -o -name '*.t' -o -name '*.psgi' \) \
                        -not -path './vendor/*' -not -path './node_modules/*' -not -path './.git/*' -print0 \
                        | xargs -0 perltidy -pro=.perltidyrc -b; status=$?;
                    find . -type f \( -name '*.pl.bak' -o -name '*.pm.bak' -o -name '*.t.bak' -o -name '*.psgi.bak' \) -delete 2>/dev/null || true;
                    exit $status;
             else
                    exit 0;
             fi}
);

# Shell formatting (shfmt) — required (fail if missing); rely on .editorconfig
run_command(
  "shfmt",
  "sh",
  "-c",
q{if find . -type f -name '*.sh' -not -path './vendor/*' -not -path './node_modules/*' -not -path './.git/*' -print -quit | grep -q .; then
             find . -type f -name '*.sh' \
                -not -path './vendor/*' -not -path './node_modules/*' -not -path './.git/*' -print0 \
                | xargs -0 shfmt -w;
         else
             exit 0;
         fi}
);

run_command("eslint", "bun", "eslint", ".", "--fix");
run_command("Stylelint", "sh", "-c", "bun stylelint '**/*.scss' --fix");
run_command("Coffeelint Fix", "sh", "-c",
"command -v bun >/dev/null && bun coffeelint --help >/dev/null 2>&1 && find . -name '*.coffee' -not -path './node_modules/*' -print0 | xargs -0 -r bun coffeelint --fix -f coffeelint.json || true"
);
run_command("markdownlint", "sh", "-c",
"bun markdownlint-cli2 '**/*.md' '!**/node_modules/**' '!**/licenses/**' '!**/.codeql/**' --fix --config .markdownlint-cli2.jsonc"
);
run_command("bundle update", "bundle", "update");
run_command("bun update",    "bun",    "update");
# Remove manual Haml Validation and replace i18n validation
# run_command("Haml Validation", "rake", "haml:check");
run_command("i18n Validation", "ruby", "scripts/i18n_validate.rb");

# CodeQL automatic setup and database creation (sequential - ensures setup is ready)
print "CodeQL Setup [RUNNING]\n";
my $codeql_setup_exit = system("scripts/codeql-local.sh", "--setup-only");
if ($codeql_setup_exit == 0) {
  print "CodeQL Setup [OK]\n";
  push @sequential_status, "[OK]";
} else {
  print "CodeQL Setup [NOTOK] (Exit Code: " . ($codeql_setup_exit >> 8) . ")\n";
  push @sequential_status, "[NOTOK]";
}
push @sequential_tools, "CodeQL Setup";

# --- Parallel Execution Setup ---
my $log_dir = tempdir(CLEANUP => 1);    # Auto-cleanup
# print "(Storing parallel task logs in $log_dir)\n";

# Use a hash for storing PIDs and related info
my %child_info;

# END block for cleanup (though File::Temp handles the dir)
END {
  # print "Cleaning up temporary log directory: $log_dir\n";
}

# Function to run a command in the background and log output
sub run_in_background {
  my ($tool_index, $tool_name, @cmd) = @_;

  my $log_filename = $tool_name;
  $log_filename =~ tr/A-Z/a-z/;
  $log_filename =~ tr/ /_/s;
  my $log_file = "$log_dir/${log_filename}.log";

  $tool_log_files[$tool_index] = $log_file;

  my $pid = fork();
  die "Cannot fork for $tool_name: $!" unless defined $pid;

  if ($pid == 0) {
    # Child process
    open STDOUT, ">", $log_file
      or die "Cannot redirect STDOUT to $log_file: $!";
    open STDERR, ">&", STDOUT or die "Cannot dup STDOUT for STDERR: $!";
    select((select(STDOUT), $| = 1)[0]);    # Autoflush
    select((select(STDERR), $| = 1)[0]);    # Autoflush

    print STDOUT "--------------------------------------------------\n";
    print STDOUT "--- $tool_name Results ---\n";
    print STDOUT "--------------------------------------------------\n";

    # Use system for simplicity, exec is also an option
    system(@cmd);
    my $child_exit_code = $? >> 8;

    print STDOUT "\n--------------------------------------------------\n";
    print STDOUT
      "--- End of $tool_name Results (Exit Code: $child_exit_code) ---\n";
    print STDOUT "--------------------------------------------------\n";

    exit $child_exit_code;    # Exit child with the command's exit code
  }
  # Parent process
  $pids[$tool_index] = $pid;
}

# --- Define and run parallel commands ---
@parallel_tools = ("Fasterer", "Typos", "Jest", "Brakeman");
# TEMPORARILY DISABLED: "CodeQL Ruby", "CodeQL JavaScript"
my $num_tools = scalar @parallel_tools;

for my $i (0 .. $num_tools - 1) {
  my $tool_name = $parallel_tools[$i];
  $tool_exit_codes[$i] = -1;         # Initialize placeholder
  $parallel_status[$i] = "[PEND]";

  my @cmd;
  if ($tool_name eq "Fasterer") {
    @cmd = ("fasterer");
  } elsif ($tool_name eq "UNUSED_PLACEHOLDER")
  {    # placeholder to keep elsif structure consistent if needed later
    @cmd = ("true");
  } elsif ($tool_name eq "Typos") {
    @cmd = ("typos");
  } elsif ($tool_name eq "Jest") {
    @cmd = (
      "sh", "-c",
      "NODE_OPTIONS='--experimental-vm-modules' npx jest --coverage=false"
    );
  } elsif ($tool_name eq "Brakeman") {
    @cmd = ("brakeman", "--quiet", "--no-summary", "--no-pager");
# TEMPORARILY DISABLED - CodeQL local analysis needs fixes
# } elsif ($tool_name eq "CodeQL Ruby") {
#     @cmd = ("scripts/codeql-local.sh", "--language", "ruby", "--no-summary", "--no-create-db");
# } elsif ($tool_name eq "CodeQL JavaScript") {
#     @cmd = ("scripts/codeql-local.sh", "--language", "javascript", "--no-summary", "--no-create-db");
  }

  run_in_background($i, $tool_name, @cmd);
}

# --- Wait for all background jobs and collect exit codes ---
for my $i (0 .. $num_tools - 1) {
  my $pid       = $pids[$i];
  my $tool_name = $parallel_tools[$i];

  next if defined $pid && $pid == 0;    # Skip tasks marked as skipped
  unless (defined $pid) {               # Handle case where task wasn't launched
    warn "No PID found for $tool_name (index $i), skipping wait.\n";
    $parallel_status[$i] = "[ERROR]";
    next;
  }

  waitpid($pid, 0);
  my $exit_code = $? >> 8;
  $tool_exit_codes[$i] = $exit_code;

  if ($exit_code != 0) {
    print "$tool_name [NOTOK]\n";
    $parallel_status[$i] = "[NOTOK]";
  } else {
    print "$tool_name [OK]\n";
    $parallel_status[$i] = "[OK]";
  }
}

# --- Print results from log files ---
my $any_logs_printed = 0;
for my $i (0 .. $num_tools - 1) {
  my $tool_name = $parallel_tools[$i];
  my $log_file  = $tool_log_files[$i];
  my $exit_code = $tool_exit_codes[$i];
  my $pid       = $pids[$i];

# Only print log if the task actually ran (pid defined and != 0) AND failed (exit_code != 0)
  if (defined $pid && $pid != 0 && defined $exit_code && $exit_code != 0) {
    if (-f $log_file) {
      print "\n--- Log for $tool_name --- (Exit Code: $exit_code)\n";
      open my $log_fh, '<', $log_file or do {
        warn "Could not open log file $log_file: $!";
        next;
      };
      print <$log_fh>;
      close $log_fh;
      $any_logs_printed = 1;
    } else {
      print "\n!!! ERROR: Log File Not Found for $tool_name ($log_file) !!!\n";
      $any_logs_printed = 1;
    }
  }
}

print "\n" if $any_logs_printed;

# Determine exit code based on failures
my $exit_code = 0;
$exit_code = 1 if grep { $_ eq '[NOTOK]' } @sequential_status, @parallel_status;
exit $exit_code;
