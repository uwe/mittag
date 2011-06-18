package Mittag::DB::Schema;

use strict;
use warnings;

use parent 'DBIx::Class::Schema';

use Carp qw/croak/;


__PACKAGE__->load_classes;


sub connect_with_config {
    my ($class, $config) = @_;

    foreach (qw/db_name db_user db_pass/) {
        croak "$_ missing in config" unless defined $config->{$_};
    }

    my @connect = (
        'dbi:mysql:' . $config->{db_name},
        $config->{db_user},
        $config->{db_pass},
        {mysql_enable_utf8 => 1},
    );

    return $class->connect(@connect);
}


1;
