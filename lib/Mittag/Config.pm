package Mittag::Config;

use strict;
use warnings;

use Carp qw/croak/;


sub new {
    my ($class, $path) = @_;

    croak 'path missing' unless $path;

    my $config_file = $path . '/config.pl';
    my $local_file  = $path . '/config-local.pl';

    my $config = do $config_file;

    # merge local config (shallow merge)
    if (-f $local_file) {
        my $local = do $local_file;
        $config = { %$local, %$config };
    }

    return bless $config, $class;
}


1;
