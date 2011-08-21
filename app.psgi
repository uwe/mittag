#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Plack::Builder;

use lib $FindBin::Bin . '/lib';
use Mittag::Config;
use Mittag::WebNano;


my $config  = Mittag::Config->new($FindBin::Bin);
my $webnano = Mittag::WebNano->new(config => $config);

my $app = $webnano->psgi_app;


builder {
    enable
        'Plack::Middleware::Static',
        # put all static files here
        path => qr{^/(favicon.ico|robots.txt|main.css|geo.js)$},
        root => $FindBin::Bin.'/static/';

    $app;
};
