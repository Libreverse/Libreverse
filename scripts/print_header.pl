#!/usr/bin/env perl
use strict;
use warnings;
use Term::ANSIColor;  # For colored output
use utf8;  # Enable UTF-8 for Unicode
binmode STDOUT, ':encoding(UTF-8)';  # Set output encoding to UTF-8

# Get terminal width
my $width = `tput cols` || 80;  # Default to 80 if tput fails
chomp $width;
my $box_width = 78;  # Fixed box width for better fit
my $line = "═" x ($box_width);  # Unicode double line for polished look

# ANSI helpers for 256-color foreground and reset
my $RESET = "\e[0m";
sub _ansi_fg { my ($n) = @_; return sprintf("\e[38;5;%dm", $n); }

# Define fixed colors for different message types
my $header_color = _ansi_fg(182);

# Clear screen for a fresh start
system('clear');

# Define banner lines
my @banner = (
    "  / /(_) |__  _ __ _____   _____ _ __ ___  ___ ",
    " / / | | '_ \\| '__/ _ \\ \\ / / _ \\ '__/ __|/ _ \\",
    "/ /__| | |_) | | |  __/\\ V /  __/ |  \\__ \\  __/",
    "\\____/_|_.__/|_|  \\___| \\_/ \\___|_|  |___/\\___|"
);

# Print header with banner
print $header_color;
print "╔$line╗\n";
foreach my $banner_line (@banner) {
    my $len = length($banner_line);
    my $side_spaces = int(($box_width - ($len + 1)) / 2);
    print "║", " " x $side_spaces, $banner_line, " " x $side_spaces, " ║\n";
}
print "╚$line╝\n";
print $RESET;