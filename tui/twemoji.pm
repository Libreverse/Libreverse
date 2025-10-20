package Twemoji;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(twemoji);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

use File::Basename qw(dirname);
use Cwd qw(realpath);
use File::Temp qw(tempfile);
use MIME::Base64 qw(encode_base64);
use utf8;

use constant DEFAULT_WIDTH => 72;
use constant DEFAULT_HEIGHT => 72;

sub twemoji {
    my ($char, $opts) = @_;
    $opts ||= {};

    die "char required" unless defined $char && length($char);

    my $codepoint = ord($char);  # Assume single codepoint; extend for sequences later

    # Auto-locate emoji directory
    my $emoji_dir;
    unless (exists $opts->{emoji_dir}) {
        my $module_dir = dirname(realpath(__FILE__));
        $emoji_dir = $module_dir . '/../app/emoji';
        -d $emoji_dir or die "Default emoji directory '$emoji_dir' not found next to module";
    } else {
        $emoji_dir = $opts->{emoji_dir};
    }

    my $width = $opts->{width} || DEFAULT_WIDTH;
    my $height = $opts->{height} || DEFAULT_HEIGHT;

    my $hex = sprintf('%x', $codepoint);
    my $svg_file = $emoji_dir . '/' . $hex . '.svg';
    if (-f $svg_file) {
        # Try to render as image
        my ($png_fh, $png_filename) = tempfile(SUFFIX => '.png');
        close $png_fh;
        if (system("magick $svg_file -resize ${width}x${height} $png_filename") == 0) {
            open my $fh, '<:raw', $png_filename or return $char;
            my $png_blob = do { local $/; <$fh> };
            close $fh;
            unlink $png_filename;
            my $b64 = encode_base64($png_blob, '');

            my $term = $ENV{TERM} || '';
            my $term_program = $ENV{TERM_PROGRAM} || '';
            if ($term =~ /kitty/i) {
                # Kitty protocol
                return "\x1b_Ga;T=f,0,0,$width,$height;q=100;I=$b64\x1b\\";
            } elsif ($term_program =~ /iTerm/i || $term =~ /iterm/i) {
                # iTerm2 inline image protocol
                my $size = length($b64);
                return "\e]1337;File=inline=1;width=${width}px;height=${height}px;size=$size:$b64\a";
            } else {
                # Fallback to native emoji
                return $char;
            }
        } else {
            # magick failed, fallback
            return $char;
        }
    } else {
        # No SVG, fallback to native
        return $char;
    }
}

1;  # End of module
