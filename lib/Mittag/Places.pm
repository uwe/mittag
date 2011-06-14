package Mittag::Places;

# place factory

use strict;
use warnings;

use Module::Find qw/useall/;


my @places = useall 'Mittag::Place';
my %place  = map { $_->id => $_->new } @places;


sub place_by_id {
    my ($class, $id) = @_;

    return $place{$id};
}


1;
