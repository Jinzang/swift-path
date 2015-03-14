#!/usr/bin/env perl
# combine -- build a single file from the individual files

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Cwd;
use IO::File;
use Getopt::Std;
use File::Spec::Functions qw(catfile splitdir);

use Common;

#----------------------------------------------------------------------
# Configuration

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

my ($output_name, $directory_name) = shift @ARGV;
die "No output file" unless $output_name;

if ($directory_name) {
    chdir($directory_name)
        or die "Can't find $directory_name\n";
}

my ($formatter, $template_name) = get_formatter($formatters, $templates,
                                                $output_name);

my $index= read_file($index_name);
my @file_names = parse_index($index);

my $output = combine_files($formatter, $template_name, \@sections, @file_names);
write_file($output_name, $output);

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
