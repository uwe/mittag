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
        $config = { %$config, %$local };
    }

    # check for undef
    while (my ($key, $value) = each %$config) {
        next if defined $value;
        croak "Config key '$key' not specified in config-local.pl";
    }

    # expand base path
    foreach my $value (values %$config) {
        $value =~ s/__BASE__/$path/;
    }

    return bless $config, $class;
}


1;
