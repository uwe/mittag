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
    path   => '.',
});

print $downloader->pdf2txt($ARGV[0]);
