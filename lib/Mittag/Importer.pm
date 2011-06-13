package Mittag::Importer;

# save meals to database

use strict;
use warnings;

use base qw/Class::Accessor::Faster/;

use Carp       qw/croak/;
use Data::Dump qw/pp/;
use DateTime;


__PACKAGE__->mk_ro_accessors(qw/schema/);


sub save_weekly {
    my ($self, %arg) = @_;

    foreach (qw/name week meal price/) {
        croak "$_ missing" unless $arg{$_};
    }

    my $place = $self->_place_by_name($arg{name});

    my ($from, $to) = __from_to($arg{week});

    return $self->schema->resultset('Mittag::Schema::WeeklyOffer')->find_or_create(
        place_id  => $place->id,
        from_date => $from,
        to_date   => $to,
        name      => $arg{meal},
        price     => $arg{price},
    );
}

sub save {
    my ($self, %arg) = @_;

    foreach (qw/name date meal price/) {
        croak "$_ missing" unless $arg{$_};
    }

    my $place = $self->_place_by_name($arg{name});

    return $self->schema->resultset('Mittag::Schema::DailyOffer')->find_or_create({
        place_id  => $place->id,
        date      => $arg{date},
        name      => $arg{meal},
        price     => $arg{price},
    });
}

sub _place_by_name {
    my ($self, $name) = @_;

    return $self->schema->resultset('Mittag::Schema::Place')->find_or_create({
        name => $name,
    });
}

sub __from_to {
    my ($date) = @_;

    my ($y, $m, $d) = split /-/, $date;
    my $dt = DateTime->new(year => $y, month => $m, day => $d);

    # monday or friday?
    if ($dt->dow == 1) {
        return (
            $dt->ymd('-'),
            $dt->clone->add(days => 4)->ymd('-'),
        );
    }
    elsif ($dt->dow == 5) {
        return (
            $dt->clone->subtract(days => 4)->ymd('-'),
            $dt->ymd('-'),
        );
    }
    else {
        die sprintf("Unexpected weekday (%d): %s", $dt->dow, $dt->ymd('-'));
    }
}


1;
