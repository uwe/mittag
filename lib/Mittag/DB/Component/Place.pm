package Mittag::DB::Component::Place;

use strict;
use warnings;

use base qw/DBIx::Class/;

use Mittag::Places;


sub place {
    my ($self) = @_;

    return Mittag::Places->place_by_id($self->place_id);
}


1;
