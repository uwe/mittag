#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Module::Find qw/useall/;

use lib $FindBin::Bin . '/../lib';
use Mittag::Downloader;


my $path = $FindBin::Bin . '/../data';


my $downloader = Mittag::Downloader->new({path => $path});
my @places = useall 'Mittag::Place';
foreach my $class (@places) {
    $class->download($downloader);
}
