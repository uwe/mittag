#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Module::Find qw/useall/;

use lib $FindBin::Bin . '/../lib';
use Mittag::Config;
use Mittag::Downloader;


my $config     = Mittag::Config->new($FindBin::Bin . '/..');
my $downloader = Mittag::Downloader->new({
    config => $config,
    path   => $config->{path_web},
});

my @places = useall 'Mittag::Place';
foreach my $class (@places) {
    next unless $class->type eq 'web';
    $class->download($downloader);
}
