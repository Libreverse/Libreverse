#!/usr/bin/env perl
use strict;
use warnings;

# Define colors from the provided palette
my %COLORS = (
  reset  => "\033[0m",
  bold   => "\033[1m",
  red    => "\033[38;5;174m",
  yellow => "\033[38;5;150m",
  cyan   => "\033[38;5;115m",
);

# Get terminal width
my $width = `tput cols` || 80;
chomp $width;

# Function to center text, accounting for ANSI escape codes
sub center {
  my ($text) = @_;
  # Remove ANSI escape codes for length calculation
  my $clean_text = $text;
  $clean_text =~ s/\x1b\[[0-9;]*m//g;
  my $text_length = length($clean_text);
  my $padding     = int(($width - $text_length) / 2);
  if ($padding > 0) {
    return (' ' x $padding) . $text . "\n";
  } else {
    return $text . "\n";
  }
}

# Print centered messages
print "\n";
print center($COLORS{red}
    . $COLORS{bold}
    . "=================================================="
    . $COLORS{reset});
print center($COLORS{red}
    . $COLORS{bold}
    . "          LIBREVERSE DEVELOPMENT STARTUP IN PROGRESS...           "
    . $COLORS{reset});
print center($COLORS{yellow}
    . " This process may take several minutes.           "
    . $COLORS{reset});
print center($COLORS{yellow}
    . " Please do NOT interrupt or close the terminal!   "
    . $COLORS{reset});
print center($COLORS{red}
    . $COLORS{bold}
    . "=================================================="
    . $COLORS{reset});
print "\n";
