#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Temp;

print "Installing\n";

# Helper to check if a command exists
sub command_exists {
    my ($cmd) = @_;
    return system("command -v $cmd >/dev/null 2>&1") == 0;
}

# Install Ruby if not present
unless (command_exists('ruby')) {
    print "  Ruby not found. Installing Ruby (via Homebrew)...\n";
    system("brew install ruby") == 0 or die "Failed to install Ruby";
} else {
    print "  Ruby is already installed.\n";
}

# Install Node if not present
unless (command_exists('node')) {
    print "  Node.js not found. Installing Node.js (via Homebrew)...\n";
    system("brew install node") == 0 or die "Failed to install Node.js";
} else {
    print "  Node.js is already installed.\n";
}

# Install Bun if not present
unless (command_exists('bun')) {
    print "  Bun not found. Installing Bun (via install script)...\n";
    
    # Create a secure temporary file for the install script
    my $temp_fh = File::Temp->new(
        TEMPLATE => 'bun_install_XXXXXX',
        SUFFIX   => '.sh',
        UNLINK   => 0  # We'll handle cleanup manually for better error handling
    );
    my $temp_script = $temp_fh->filename;
    close $temp_fh;  # Close the filehandle but keep the file
    
    # Download the install script securely
    my $download_cmd = "curl -fsSL --tlsv1.2 --proto '=https' --max-time 30 --retry 3 -o '$temp_script' 'https://bun.sh/install'";
    if (system($download_cmd) != 0) {
        unlink $temp_script if -f $temp_script;
        die "Failed to download Bun install script";
    }
    
    # Basic validation: check if file exists and has reasonable size (>1KB, <1MB)
    unless (-f $temp_script) {
        die "Downloaded install script not found";
    }
    
    my $file_size = -s $temp_script;
    unless ($file_size > 1024 && $file_size < 1048576) {
        unlink $temp_script;
        die "Downloaded install script has suspicious size: $file_size bytes";
    }
    
    # Check if file starts with shebang (basic shell script validation)
    open my $fh, '<', $temp_script or die "Cannot read install script: $!";
    my $first_line = <$fh>;
    close $fh;
    
    unless ($first_line && $first_line =~ /^#!/) {
        unlink $temp_script;
        die "Downloaded file doesn't appear to be a shell script";
    }
    
    # Make script executable and run it
    chmod 0755, $temp_script or die "Cannot make install script executable: $!";
    my $install_result = system("bash '$temp_script'");
    
    # Clean up temporary file
    unlink $temp_script;
    
    if ($install_result != 0) {
        die "Failed to install Bun";
    }
    
    # Add Bun to PATH for this session if installed in ~/.bun
    $ENV{PATH} = "$ENV{HOME}/.bun/bin:$ENV{PATH}";
} else {
    print "  Bun is already installed.\n";
}

# Install typos if not present
unless (command_exists('typos')) {
    print "  Typos not found. Installing typos (via gh-install)...\n";
    
    # Detect operating system
    my $is_windows = ($^O eq 'MSWin32' || $^O eq 'cygwin');
    my $is_macos = ($^O eq 'darwin');
    
    # Get the directory where this script is located
    use Cwd qw(abs_path);
    use File::Copy qw(copy);
    my $script_dir = abs_path($0);
    $script_dir =~ s/\/[^\/]+$//;  # Remove filename to get directory
    my $gh_install_dir = "$script_dir/scripts";
    
    # Set up installation paths and script based on OS
    my ($install_dir, $install_script, $script_extension);
    
    $install_dir = "$ENV{HOME}/.cargo/bin";
    $script_extension = ".sh";
    $install_script = "/tmp/gh-install.sh";
    
    # Create installation directory if it doesn't exist
    unless (-d $install_dir) {
        if ($is_windows) {
            system("mkdir", "\"$install_dir\"");
        } else {
            system("mkdir", "-p", $install_dir);
        }
        if ($? != 0) {
            die "Failed to create directory $install_dir";
        }
    }
    
    # Copy local gh-install script to temp location
    my $local_script = "$gh_install_dir/gh-install$script_extension";
    unless (-f $local_script) {
        die "Local gh-install script not found at $local_script";
    }
    
    # Copy local gh-install script to temp location using File::Copy for portability
    unless (copy($local_script, $install_script)) {
        die "Failed to copy local gh-install script from $local_script to $install_script: $!";
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
        die "Failed to install typos (exit code: $install_exit_code)";
    }
    
    # Add appropriate bin directories to PATH for this session
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
    
    print "  Typos installed successfully.\n";
} else {
    print "  Typos is already installed.\n";
}

# Install CodeQL CLI automatically
print "  Installing CodeQL CLI (for security analysis)...\n";
my $codeql_exit_code = system("scripts/codeql-local.sh", "--install");
if ($codeql_exit_code == 0) {
    print "  CodeQL CLI installed successfully.\n";
} else {
    print "  Warning: CodeQL CLI installation failed. Security analysis may not work.\n";
    # Don't fail the entire setup for CodeQL
}

my @pids;
my %child_status;

# Run bundle install in background
my $pid1 = fork();
die "Cannot fork: $!" unless defined $pid1;
if ($pid1 == 0) {
    print "  Starting bundle install...\n";
    exec("bundle", "install") or die "Cannot exec bundle install: $!";
}
push @pids, $pid1;

# Run bun install in background
my $pid2 = fork();
die "Cannot fork: $!" unless defined $pid2;
if ($pid2 == 0) {
    print "  Starting bun install...\n";
    exec("bun", "install") or die "Cannot exec bun install: $!";
}
push @pids, $pid2;

# Wait for both processes
my $errors = 0;
foreach my $pid (@pids) {
    waitpid($pid, 0);
    my $exit_code = $? >> 8;
    my $cmd = ($pid == $pid1) ? "bundle install" : "bun install";
    if ($exit_code != 0) {
        print "!!! $cmd failed with exit code $exit_code !!!\n";
        $errors = 1;
    } else {
        print "  Finished $cmd successfully.\n";
    }
}

if ($errors) {
    print "!!! Setup finished with errors !!!\n";
    exit 1;
} else {
    print "Finished installing\n";
    exit 0;
}