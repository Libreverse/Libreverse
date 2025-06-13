#!/usr/bin/env perl

use strict;
use warnings;
use File::Temp qw(tempfile tempdir);
use File::Path qw(remove_tree);
use Cwd qw(abs_path);
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

# --- Tool Installation Functions ---
sub install_typos {
    # Detect operating system
    my $is_windows = ($^O eq 'MSWin32' || $^O eq 'cygwin');
    my $is_macos = ($^O eq 'darwin');
    
    # Define potential paths for typos
    my @typos_paths = (
        "$ENV{HOME}/.cargo/bin/typos",
        "/usr/local/bin/typos",  # Homebrew on Intel Mac
        "/opt/homebrew/bin/typos",  # Homebrew on Apple Silicon Mac
    );
    
    # Add Windows paths if on Windows
    if ($is_windows) {
        push @typos_paths, "$ENV{USERPROFILE}\\.cargo\\bin\\typos.exe";
        push @typos_paths, "$ENV{PROGRAMFILES}\\typos\\typos.exe";
    }
    
    # Check if typos is already installed in any of the common locations
    for my $typos_path (@typos_paths) {
        if (-x $typos_path) {
            print "Typos already installed at $typos_path\n";
            return 1;
        }
    }
    
    # Check if typos is in PATH
    my $which_cmd = $is_windows ? "where typos 2>nul" : "which typos 2>/dev/null";
    my $which_result = qx($which_cmd);
    chomp $which_result;
    if ($which_result && -x $which_result) {
        print "Typos found in PATH at $which_result\n";
        return 1;
    }
    
    # Check for Homebrew installation on macOS
    if ($is_macos) {
        my $brew_result = qx(brew list typos 2>/dev/null);
        if ($? == 0) {
            my $brew_typos = qx(brew --prefix typos 2>/dev/null);
            chomp $brew_typos;
            if ($brew_typos) {
                print "Typos found via Homebrew at $brew_typos\n";
                return 1;
            }
        }
    }
    
    print "Installing typos using gh-install...\n";
    
    # Get the directory where this script is located
    my $script_dir = abs_path($0);
    $script_dir =~ s/\/[^\/]+$//;  # Remove filename to get directory
    my $gh_install_dir = "$script_dir/scripts";
    
    # Set up installation paths and script based on OS
    my ($install_dir, $install_script, $script_extension);
    
    if ($is_windows) {
        $install_dir = "$ENV{USERPROFILE}\\.cargo\\bin";
        $script_extension = ".ps1";
        $install_script = "$ENV{TEMP}\\gh-install.ps1";
    } else {
        $install_dir = "$ENV{HOME}/.cargo/bin";
        $script_extension = ".sh";
        $install_script = "/tmp/gh-install.sh";
    }
    
    # Create installation directory if it doesn't exist
    unless (-d $install_dir) {
        if ($is_windows) {
            system("mkdir", "\"$install_dir\"");
        } else {
            system("mkdir", "-p", $install_dir);
        }
        if ($? != 0) {
            warn "Failed to create directory $install_dir\n";
            return 0;
        }
    }
    
    # Copy local gh-install script to temp location
    my $local_script = "$gh_install_dir/gh-install$script_extension";
    unless (-f $local_script) {
        warn "Local gh-install script not found at $local_script\n";
        return 0;
    }
    
    my $copy_cmd = $is_windows ? ["copy", "\"$local_script\"", "\"$install_script\""] : ["cp", $local_script, $install_script];
    system(@$copy_cmd);
    if ($? != 0) {
        warn "Failed to copy local gh-install script from $local_script\n";
        return 0;
    }
    
    # Run gh-install to install typos
    my ($install_cmd, $install_exit_code);
    
    if ($is_windows) {
        # On Windows, run PowerShell script
        $install_cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", $install_script, "-Git", "crate-ci/typos"];
    } else {
        # On Unix-like systems, make script executable and run
        chmod 0755, $install_script;
        $install_cmd = [$install_script, "--git", "crate-ci/typos"];
    }
    
    system(@$install_cmd);
    $install_exit_code = $? >> 8;
    
    # Clean up script
    unlink $install_script;
    
    if ($install_exit_code != 0) {
        warn "Failed to install typos (exit code: $install_exit_code)\n";
        return 0;
    }
    
    # Verify installation by checking all possible paths again
    for my $typos_path (@typos_paths) {
        if (-x $typos_path) {
            print "Typos successfully installed at $typos_path\n";
            return 1;
        }
    }
    
    # Final check in PATH
    $which_result = qx($which_cmd);
    chomp $which_result;
    if ($which_result && -x $which_result) {
        print "Typos successfully installed and found in PATH at $which_result\n";
        return 1;
    }
    
    warn "Typos installation completed but binary not found at expected locations\n";
    return 0;
}

# --- Sequential Tasks --- Function to run and check command
sub run_command {
    my ($tool_name, @cmd) = @_;
    my $status = "[OK]";
    my @output;
    my $exit_code = 0; # Default to success

    push @sequential_tools, $tool_name;

    # Use IPC::Open3 to capture STDOUT and STDERR separately
    my $stdout_fh = gensym; # Create anonymous filehandles
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
             print @output; # Print combined STDOUT and STDERR
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
my ($prettier_fh, $prettier_output_log) = tempfile(UNLINK => 1); # Auto-cleanup

my $prettier_cmd = ["bun", "prettier", "--write", "."];
my $prettier_exit_code;
my @prettier_raw_output;

# Set timeout using Perl's alarm (basic timeout)
local $SIG{ALRM} = sub { die "Prettier timeout\n" };
alarm(30); # 30 second timeout
eval {
    open(my $prettier_out_fh, "-|", @$prettier_cmd) or die "Failed to run Prettier: $!";
    @prettier_raw_output = <$prettier_out_fh>;
    close $prettier_out_fh;
    $prettier_exit_code = $? >> 8;
};
alarm(0); # Cancel alarm

if ($@) { # Check if eval died (e.g., timeout or execution failure)
    warn "$@";
    $prettier_exit_code = 1; # Mark as failed
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
run_command("Rubocop",      "bundle", "exec", "rubocop", "-A");
run_command("haml-lint",    "bundle", "exec", "haml-lint", "--auto-correct", ".");
run_command("eslint",       "bun", "eslint", ".", "--fix");
run_command("Stylelint",    "sh", "-c", "bun stylelint '**/*.scss' --fix");
run_command("markdownlint", "sh", "-c", "bun markdownlint-cli2 '**/*.md' '!**/node_modules/**' '!**/licenses/**' --fix --config .markdownlint.json");
run_command("bundle update", "bundle", "update");
run_command("bun update", "bun", "update");
run_command("bundle-audit", "bundle-audit", "check", "--update");
run_command("npm audit (production only)", "sh", "-c", 
    "npm i --package-lock-only --omit=dev --omit=optional --omit=peer --legacy-peer-deps --force && " .
    "npm audit --audit-level=moderate; " .
    "exit_code=\$?; " .
    "rm -f package-lock.json; " .
    "exit \$exit_code");
run_command("Haml Validation", "rake", "haml:check");
run_command("i18n Validation", "rake", "i18n:validate_keys");

# --- Parallel Execution Setup ---
my $log_dir = tempdir(CLEANUP => 1); # Auto-cleanup
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
        open STDOUT, ">", $log_file or die "Cannot redirect STDOUT to $log_file: $!";
        open STDERR, ">&", STDOUT or die "Cannot dup STDOUT for STDERR: $!";
        select((select(STDOUT), $| = 1)[0]); # Autoflush
        select((select(STDERR), $| = 1)[0]); # Autoflush

        print STDOUT "--------------------------------------------------\n";
        print STDOUT "--- $tool_name Results ---\n";
        print STDOUT "--------------------------------------------------\n";

        # Use system for simplicity, exec is also an option
        system(@cmd);
        my $child_exit_code = $? >> 8;

        print STDOUT "\n--------------------------------------------------\n";
        print STDOUT "--- End of $tool_name Results (Exit Code: $child_exit_code) ---\n";
        print STDOUT "--------------------------------------------------\n";

        exit $child_exit_code; # Exit child with the command's exit code
    }
    # Parent process
    $pids[$tool_index] = $pid;
}

# --- Define and run parallel commands ---
my @coffee_files;
# Use backticks with find to mimic bash script
my $find_output = qx(find . -path ./node_modules -prune -o -name '*.coffee' -print0);
@coffee_files = split /\0/, $find_output;

@parallel_tools = ("Fasterer", "Coffeelint", "Typos", "Jest", "Rails test", "Brakeman");
my $num_tools = scalar @parallel_tools;

for my $i (0 .. $num_tools - 1) {
    my $tool_name = $parallel_tools[$i];
    $tool_exit_codes[$i] = -1; # Initialize placeholder
    $parallel_status[$i] = "[PEND]";

    my @cmd;
    if ($tool_name eq "Fasterer") {
        @cmd = ("fasterer");
    } elsif ($tool_name eq "Coffeelint") {
        if (@coffee_files) {
            @cmd = ("bun", "coffeelint", "-f", "coffeelint.json", @coffee_files);
        } else {
            print "  [ SKIP] Coffeelint: No .coffee files found.\n";
            $pids[$i] = 0;
            $tool_exit_codes[$i] = 0;
            $parallel_status[$i] = "[SKIP]";
            my $log_file = "$log_dir/coffeelint.log";
            $tool_log_files[$i] = $log_file;
            open my $skip_fh, '>', $log_file or warn "Cannot create skip log $log_file: $!";
            if ($skip_fh) {
                print $skip_fh "--------------------------------------------------\n";
                print $skip_fh "--- Coffeelint Results ---\n";
                print $skip_fh "--------------------------------------------------\n";
                print $skip_fh "Skipped: No .coffee files found.\n\n";
                print $skip_fh "--------------------------------------------------\n";
                print $skip_fh "--- End of Coffeelint Results (Exit Code: 0) ---\n";
                print $skip_fh "--------------------------------------------------\n";
                close $skip_fh;
            }
            next; # Skip running background task
        }
    } elsif ($tool_name eq "Typos") {
        # Install typos if not available
        unless (install_typos()) {
            print "  [ERROR] Typos: Failed to install typos, skipping.\n";
            $pids[$i] = 0;
            $tool_exit_codes[$i] = 1;
            $parallel_status[$i] = "[ERROR]";
            my $log_file = "$log_dir/typos.log";
            $tool_log_files[$i] = $log_file;
            open my $error_fh, '>', $log_file or warn "Cannot create error log $log_file: $!";
            if ($error_fh) {
                print $error_fh "--------------------------------------------------\n";
                print $error_fh "--- Typos Results ---\n";
                print $error_fh "--------------------------------------------------\n";
                print $error_fh "ERROR: Failed to install typos using gh-install.\n\n";
                print $error_fh "--------------------------------------------------\n";
                print $error_fh "--- End of Typos Results (Exit Code: 1) ---\n";
                print $error_fh "--------------------------------------------------\n";
                close $error_fh;
            }
            next; # Skip running background task
        }
        # Ensure appropriate bin directories are in PATH
        my $is_windows = ($^O eq 'MSWin32' || $^O eq 'cygwin');
        if ($is_windows) {
            my $cargo_bin = "$ENV{USERPROFILE}\\.cargo\\bin";
            $ENV{PATH} = "$cargo_bin;$ENV{PATH}" unless $ENV{PATH} =~ /\Q$cargo_bin\E/;
        } else {
            my $cargo_bin = "$ENV{HOME}/.cargo/bin";
            my $homebrew_intel = "/usr/local/bin";
            my $homebrew_arm = "/opt/homebrew/bin";
            $ENV{PATH} = "$cargo_bin:$ENV{PATH}" unless $ENV{PATH} =~ /\Q$cargo_bin\E/;
            $ENV{PATH} = "$homebrew_intel:$ENV{PATH}" unless $ENV{PATH} =~ /\Q$homebrew_intel\E/;
            $ENV{PATH} = "$homebrew_arm:$ENV{PATH}" unless $ENV{PATH} =~ /\Q$homebrew_arm\E/;
        }
        @cmd = ("typos");
    } elsif ($tool_name eq "Jest") {
        @cmd = ("sh", "-c", "NODE_OPTIONS='--experimental-vm-modules' npx jest --coverage=false");
    } elsif ($tool_name eq "Rails test") {
        @cmd = ("bundle", "exec", "rails", "test");
    } elsif ($tool_name eq "Brakeman") {
        @cmd = ("brakeman", "--quiet", "--no-summary", "--no-pager");
    }

    run_in_background($i, $tool_name, @cmd);
}

# --- Wait for all background jobs and collect exit codes ---
for my $i (0 .. $num_tools - 1) {
    my $pid = $pids[$i];
    my $tool_name = $parallel_tools[$i];

    next if defined $pid && $pid == 0; # Skip tasks marked as skipped
    unless (defined $pid) { # Handle case where task wasn't launched
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
    my $log_file = $tool_log_files[$i];
    my $exit_code = $tool_exit_codes[$i];
    my $pid = $pids[$i];

    # Only print log if the task actually ran (pid defined and != 0) AND failed (exit_code != 0)
    if (defined $pid && $pid != 0 && defined $exit_code && $exit_code != 0) {
        if (-f $log_file) {
            print "\n--- Log for $tool_name --- (Exit Code: $exit_code)\n";
            open my $log_fh, '<', $log_file or do {
                warn "Could not open log file $log_file: $!"; next;
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