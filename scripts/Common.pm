use strict;
use warnings;

package Common;

use IO::Dir;
use IO::File;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_paragraph read_file read_paragraph update_file visitor
                 write_file write_paragraph);

#----------------------------------------------------------------------
# Get a paragraph

sub get_paragraph {
    my ($text, $name) = @_;

    my ($para) = $text =~ /(<p class="$name">.*?<\/p>)/sm;
    return $para;
}

#----------------------------------------------------------------------
# Read a file

sub read_file {
    my ($filename) = @_;

    local $/; # to slurp the file

    my $in = IO::File->new($filename, 'r')
        or die "Couldn't open $filename: $!\n";

    my $text = <$in>;
    close($in);

    return $text;
}

#----------------------------------------------------------------------
# Read a paragraph

sub read_paragraph {
    my ($text, $name) = @_;

    my ($para) = $text =~ /<p class="$name">\n*(.*?)\n*<\/p>/sm;
    return $para;
}

#----------------------------------------------------------------------
#  Update a file

sub update_file {
    my ($filename) = @_;

    my $saved_filename = "$filename~";
    rename($filename, $saved_filename);

    return read_file($saved_filename);
}

#----------------------------------------------------------------------
# Return a closure that visits files in a directory and subdirectories

sub visitor {
    my ($top_dir, $pattern) = @_;

    my @dirlist;
    my @filelist;
    push(@dirlist, $top_dir);

    return sub {
        for (;;) {
            my $file = shift @filelist;
            return $file if defined $file;

            my $dir = shift(@dirlist);
            return unless defined $dir;

            my $dd = IO::Dir->new($dir) or die "Couldn't open $dir: $!\n";

            # Find matching files and directories
            while (defined (my $file = $dd->read())) {
                next if $file eq '.' || $file eq '..';
                my $newfile = "$dir/$file";

                if (-d $newfile) {
                     push(@dirlist, $newfile);
                } elsif ($file =~ /^$pattern$/) {
                    push(@filelist, $newfile);
                }
            }

            $dd->close;
        }

        return;
    };
}

#----------------------------------------------------------------------
#  Write text to a file

sub write_file {
    my ($filename, $text) = @_;

    my $out = IO::File->new($filename, 'w')
    or die "Couldn't open $filename: $!\n";

    print $out $text;
    close($out);

    return;
}

#----------------------------------------------------------------------
# Substitute cleaned up data back into template

sub write_paragraph {
    my ($text, $name, $para) = @_;

    my $new_text = $text;
    $new_text =~ s/<p class="$name">.*?<\/p>/<p class="$name">\n$para\n<\/p>/sm;

    return $new_text;
}

1;
