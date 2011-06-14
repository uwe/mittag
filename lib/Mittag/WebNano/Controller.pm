package Mittag::WebNano::Controller;

use strict;
use warnings;

use base qw/WebNano::Controller/;

use DateTime;


sub index_action {
    my ($self) = @_;

    my $today = DateTime->today;
    if ($today->dow > 5) {
        $today = $self->_next_date($today);
    }

    my $res = $self->req->new_response;
    $res->redirect('/day/' . $today->ymd('-'));
    return $res;
}

sub day_action {
    my ($self, $input_date) = @_;

    my @date = split /-/, $input_date;
    my $date = DateTime->new(
        year  => $date[0],
        month => $date[1],
        day   => $date[2],
    );

    my @daily  = $self->app->rs('DailyOffer')->search({date => $date->ymd('-')});

    # nothing daily - holiday?
    unless (@daily) {
        my $next_date = $self->_next_date($date, 1);

        my $res = $self->req->new_response;
        $res->redirect('/day/' . $next_date->ymd('-'));
        return $res;
    }

    my @weekly = $self->app->rs('WeeklyOffer')->search({
        from_date => {'<=' => $date->ymd('-')},
        to_date   => {'>=' => $date->ymd('-')},
    });

    my @offers = sort { $a->place->name cmp $b->place->name or $a->price <=> $b->price } (@daily, @weekly);

    my $vars = {
        OFFERS    => \@offers,
        date      => $date,
        prev_date => $self->_prev_date($date->clone->subtract(days => 1)) || undef,
        next_date => $self->_next_date($date->clone->add(     days => 1)) || undef
    };

    my $out = '';
    $self->app->tt->process('day.html', $vars, \$out);

    return $out;
}

# same date or before
sub _prev_date {
    my ($self, $date, $seek) = @_;

    my $daily = $self->app->rs('DailyOffer')->search(
        {date => {'<=' => $date->ymd('-')}},
        {order_by => {-desc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    return unless $seek;

    $daily = $self->app->rs('DailyOffer')->search(
        {},
        {order_by => {-asc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    # database empty?
    return;
}

# same date or after
sub _next_date {
    my ($self, $date, $seek) = @_;

    my $daily = $self->app->rs('DailyOffer')->search(
        {date => {'>=' => $date->ymd('-')}},
        {order_by => {-asc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    return unless $seek;

    $daily = $self->app->rs('DailyOffer')->search(
        {},
        {order_by => {-desc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    # database empty?
    return;
}


1;
