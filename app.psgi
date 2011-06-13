#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin . '/lib';
use Mittag::WebNano;


my $config = do $FindBin::Bin . '/config.pl';


Mittag::WebNano->new(config => $config)->psgi_app;
