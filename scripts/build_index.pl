#!/usr/bin/env perl
# build_index -- clean up fileformat

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use IO::File;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

use Common;

#----------------------------------------------------------------------
# Configuration

our $VERSION = '1.00';
my $index_name = 'index.html';

#----------------------------------------------------------------------
# Main routine

my %opts;
getopts('', \%opts);

my $template = update_file($index_name);
my $navigation = build_navigation();

my $output = write_paragraph($template, 'nav', $navigation);
write_file($index_name, $output);

#----------------------------------------------------------------------
# Print the help for this script

sub HELP_MESSAGE {
    print <<"EOQ";

build_index - update the index.html page

This command is run with no arguments. It assembles a list of links in
alphabetical order to each of the individual pages, which are all named
page*.html. It inserts the pages into the existing index.html page, which is
renamed to index.html~. You only need to run this command if a page is added,
deleted, or renamed.

EOQ
}

#----------------------------------------------------------------------
# Create the navigation for the index page

sub build_navigation {
    my $i = 0;
    my @links = ('Quotations:');
    foreach my $page_name (sort glob("page*.html")) {
        my ($id) = $page_name =~ /^page([^\.]+)\.html$/;
        push(@links, '<br />') if ($i ++ % 10) == 0;
        my $link = "<a href=\"$page_name\">$id</a>";
        push(@links, $link);
    }

    ##push(@links, '<br />', '<a href="glossary.html">Glossary</a>');
    my $navigation = join("\n", @links);
    return $navigation;
}
