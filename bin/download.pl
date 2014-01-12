#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use Module::Find qw/useall/;

use lib $FindBin::Bin . '/../lib';
use Mittag::Config;
use Mittag::Downloader;


my $degug = 0;
GetOptions(
    'debug|d' => \$debug,
);

my $config     = Mittag::Config->new($FindBin::Bin . '/..');
my $downloader = Mittag::Downloader->new({
    config => $config,
    debug  => $debug,
    path   => $config->{path_web},
});

my @places = useall 'Mittag::Place';
if ($ARGV[0]) {
    @places = grep { /Mittag::Place::$ARGV[0]/ } @places;
}
foreach my $class (@places) {
    next unless $class->type eq 'web';
    next if $class->disabled;

    print "$class\n" if $debug;

    eval {
        $class->download($downloader);
    };
    warn "$class: $@" if $@;
}
