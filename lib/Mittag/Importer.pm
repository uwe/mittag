package Mittag::Importer;

# save meals to database

use strict;
use warnings;

use base qw/Class::Accessor::Faster/;

use Carp qw/croak/;
use DateTime;


__PACKAGE__->mk_ro_accessors(qw/schema/);


sub save_weekly {
    my ($self, %arg) = @_;

    foreach (qw/id week meal price/) {
        croak "$_ missing" unless $arg{$_};
    }

    my ($from, $to) = __from_to($arg{week});

    return $self->schema->resultset('Mittag::Schema::WeeklyOffer')->find_or_create(
        place_id  => $arg{id},
        from_date => $from,
        to_date   => $to,
        name      => $arg{meal},
        price     => $arg{price},
    );
}

sub save {
    my ($self, %arg) = @_;

    foreach (qw/id date meal price/) {
        croak "$_ missing" unless $arg{$_};
    }

    return $self->schema->resultset('Mittag::Schema::DailyOffer')->find_or_create({
        place_id  => $arg{id},
        date      => $arg{date},
        name      => $arg{meal},
        price     => $arg{price},
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
    elsif ($dt->dow < 5) {
        warn sprintf("Unexpected weekday (%d): %s", $dt->dow, $dt->ymd('-'));

        return (
            $dt->clone->subtract(days => $dt->dow - 1)->ymd('-'),
            $dt->clone->add(days => 5 - $dt->dow)->ymd('-'),
        );
    }
    else {
        die sprintf("Unexpected weekday (%d): %s", $dt->dow, $dt->ymd('-'));
    }
}


1;
