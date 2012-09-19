package Mittag::Web::Place;

use Mojo::Base 'Mojolicious::Controller';

use Mittag::Places;

sub show {
    my ($self) = @_;

    my $place = eval { Mittag::Places->place_by_id( $self->param('id') ) };
    if (!$place) {
        return $self->render( status => 404 );
    }

    $self->stash( place => $place );
}

1;
