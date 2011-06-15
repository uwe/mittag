#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin . '/lib';
use Mittag::Config;
use Mittag::WebNano;


my $config  = Mittag::Config->new($FindBin::Bin);
my $webnano = Mittag::WebNano->new(config => $config);

my $app = $webnano->psgi_app;
