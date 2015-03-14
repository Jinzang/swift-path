#!/usr/bin/env perl

# combine -- build a single file from individual html files

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Cwd;
use IO::File;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use File::Spec::Functions qw(catfile splitdir);

use Common;

#----------------------------------------------------------------------
# Configuration

our $VERSION = '1.00';

my $index_name = 'index.html';

my $formatters = {
                  txt => \&text_formatter,
                  html => \&html_formatter,
                  md => \&markdown_formatter,
                 };

my $templates = {html => 'index.html'};

#----------------------------------------------------------------------
# Main routine

my %opts;
getopts('bwe', \%opts);
my @sections = keys %opts;
die "No output flags. Type '$0 --help' for more info\n" unless @sections;

my ($output_name, $directory_name) = @ARGV;
die "No output file" unless $output_name;

my $cwd = getcwd();
if ($directory_name) {
    chdir($directory_name) or die "Can't find $directory_name\n";
}

my ($formatter, $template_name) = get_formatter($formatters, $templates,
                                                $output_name);

my $index= read_file($index_name);
my @file_names = parse_index($index);

my $output = combine_files($formatter, $template_name, \@sections, @file_names);

chdir($cwd);
write_file($output_name, $output);

#----------------------------------------------------------------------
# Print the help for this script

sub HELP_MESSAGE {
    print <<"EOQ";

combine - Combine html files linked from the index page into one file

Synopsis:

    combine  -bew output_name [input_directory]

Flags:

You must pass at least one of the first three flags on the command line.

-b          Include paragraphs marked as bodyig in output

-e          Include paragraphs marked as english in output

-w          Include paragraphs marked as wylie in output

--help      Print this help file

--version   Print version number

The first non-flag argument to the command is the name of the output file. The
extension on the file name determines the format of the output file. Three
extensions and formats are currently supported: .html for a single web page, .md
for a markdown format file, and .txt for a plain text format file.

An optional second argument gives the name of the directory containing the
index.html file, the top page of the web site as distributed from github. All
the file names of the quotations are extracted from the index.html file and the
quotes appear in the output file in order they appear in that file. If the
second argument is omitted, it is assumed that the index.html file is in the
current directory.

More help can be read by typing:

perldoc $0

EOQ
}

#----------------------------------------------------------------------
# Combine content of files into a single file

sub combine_files {
    my ($formatter, $template_name, $sections, @file_names) = @_;

    my @paragraphs;
    $sections = sort_sections($sections);

    foreach my $file_name (@file_names) {
        my $text = read_file($file_name);

        foreach my $section (@$sections) {
            my $paragraph = read_paragraph($text, $section);
            $paragraph = &$formatter($section, $paragraph);
            push(@paragraphs, $paragraph);
        }
    }

    my $output = join('', @paragraphs);
    $output = render_template($template_name, $output)
        if defined $template_name;

    return $output;
}

#----------------------------------------------------------------------
# Get the formater to use from the extension on the output file name

sub get_formatter {
    my ($formatters, $templates, $output_name) = @_;

    my ($base, $ext) = split(/\./, $output_name);
    die "Unrecognized output file format: $output_name"
    unless exists $formatters->{$ext};

    return ($formatters->{$ext}, $templates->{$ext});
}

#----------------------------------------------------------------------
# Format html as plain text

sub html_formatter {
    my ($section, $paragraph) = @_;

    $paragraph = "\n<p class=\"$section\">\n$paragraph\n</p>\n";
    return $paragraph;
}


#----------------------------------------------------------------------
# Convert a filename to the proper format for the OS

sub map_filename {
    my ($filename) = @_;

    my @path = split(/\//, $filename);
    return catfile(@path);
}

#----------------------------------------------------------------------
# Format html as markdown

sub markdown_formatter {
    my ($section, $paragraph) = @_;

    $paragraph =~ s/<br[^>]*>/    /g;
    $paragraph =~ s/<[^>]*>//g;

    $paragraph =~ s/(.{68,78})\s+/$1\n/g if $section eq 'english';

    $paragraph = "\n$paragraph\n";
    return $paragraph;
}

#----------------------------------------------------------------------
# Parse the filenames out of the index file

sub parse_index {
    my ($index) = @_;

    my $navigation = read_paragraph($index, 'nav');
    my @file_names = $navigation =~ /href="([^"]*)"/g;
    @file_names = map {map_filename($_)} @file_names;

    return @file_names;
}

#----------------------------------------------------------------------
# Add the output to the template

sub render_template {
    my ($template_name, $output) = @_;

    my $template = read_file($template_name);
    my ($head, $tail) = split_template($template, 'content');

    return join('', $head, $output, $tail);
}

#----------------------------------------------------------------------
# Sort the sections in the order they occur in the file

sub sort_sections {
    my ($sections) = @_;

    my @new_sections;
    foreach my $possible_section (qw(bodyig wylie english)) {
        foreach my $section (@$sections) {
            if ($possible_section =~ /^$section/) {
                push(@new_sections, $possible_section);
                last;
            }
        }
    }

    return \@new_sections;
}

#----------------------------------------------------------------------
# Split the template into parts

sub split_template {
    my ($template, $tag) = @_;
    my ($head, $body, $tail);

    ($head, $body) = split(/<!--\s*section\s+$tag\s*-->/, $template);
    ($body, $tail) = split(/<!--\s*endsection\s+$tag\s*-->/, $body);

    return ($head, $tail);
}

#----------------------------------------------------------------------
# Format html as plain text

sub text_formatter {
    my ($section, $paragraph) = @_;

    $paragraph =~ s/<[^>]*>//g;
    $paragraph = "\n$paragraph\n";

    return $paragraph;
}

__END__
=encoding utf-8

=head1 NAME

combine - Combine individual html files into a single file

=head1 SYNOPSIS

    combine -b -w -e output_name [input_directory]


=head1 DESCRIPTION

Each of the quotes making up the text are in separate html files. This script
combines these separate files into a single file.

Each quotation is in three different sections: bodyig (Tibetan characters),
wylie (transliteration into latin characters), and english (the translation.)
You select which of the sections you want written to the output file by putting
the flags -b, -w, or -e on the command line, where the letter corresponds to the
first letter in the sections named previously. The flags may be combined into a
single flag and placed in any order, as is usual with Unix commands.

The first non-flag argument to the command is the name of the output file. The
extension on the file name determines the format of the output file. Three
extensions and formats are currently supported: .html for a single web page, .md
for a markdown format file, and .txt for a plain text format file.

An optional second argument gives the name of the directory containing the
index.html file, the top page of the web site as distributed from github. All
the file names of the quotations are extracted from the index.html file and the
quotes appear in the output file in order they appear in that file. If the
second argument is omitted, it is assumed that the index.html file is in the
current directory.

=head1 INSTALLATION

No intallation is necessary, but you can mark the file as executable and place
it in a directory in your path, if you wish. Otherwise, on a Unix-like OS open a
terminal window, change directories to the top directory of the quotes, and run
the command

    perl scripts/combine.pl -ebw temp/output.html

from the command line. On a Windows computer, you will first have to install
Perl, it is not distributed with Windows. I recommend installing Strawberry
Perl. It contains a terminal window. Open it, change directory to the top
directory of the quotes, and run the command

    perl scripts\combine.pl -ebw temp\output.html

The flags and arguments on the command line can be changed, as explained in the
Description section above.

=head1 LICENSE

Copyright (C) Bernie Simon.

This script is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

