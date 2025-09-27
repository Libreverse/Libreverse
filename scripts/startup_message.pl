#!/usr/bin/env perl
use strict;
use warnings;

# Define colors from the provided palette
my %COLORS = (
  reset  => "\033[0m",
  red    => "\033[38;5;174m",
  yellow => "\033[38;5;150m",
  cyan   => "\033[38;5;115m",
);

# Print messages as regular text (left-aligned)
print "\n";
print $COLORS{red}
  . $COLORS{cyan}
  . "=================================================="
  . $COLORS{reset} . "\n";
print $COLORS{red}
  . $COLORS{cyan}
  . "Libreverse development startup in progress..."
  . $COLORS{reset} . "\n";
print $COLORS{yellow}
  . "This process may take a few minutes."
  . $COLORS{reset} . "\n";
print $COLORS{yellow}
  . "Please do not interrupt or close the terminal unless the time has gotten "
  . "\033[3mreally\033[23m"
  . " long."
  . $COLORS{reset} . "\n";
print $COLORS{red}
  . $COLORS{cyan}
  . "=================================================="
  . $COLORS{reset} . "\n";
print "\n";
