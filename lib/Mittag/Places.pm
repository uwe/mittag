package Mittag::Places;

# place factory

use strict;
use warnings;

use Module::Find qw/useall/;


my @places = useall 'Mittag::Place';
my %place  = ();
foreach my $place (@places) {
    my $id = $place->id;
    # 12: Paparazzi and Pararazzi2
    die "ID $id used twice: $place{$id}" if $place{$id} and $id != 12;
    $place{$id} = $place->new;
}


sub place_by_id {
    my ($class, $id) = @_;

    return $place{$id};
}


1;
