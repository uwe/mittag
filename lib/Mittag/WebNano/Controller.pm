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
        my $next_date = $self->_next_date($date);

        my $res = $self->req->new_response;
        $res->redirect('/day/' . $next_date->ymd('-'));
        return $res;
    }

    my @weekly = $self->app->rs('WeeklyOffer')->search({
        from_date => {'<=' => $date->ymd('-')},
        to_date   => {'>=' => $date->ymd('-')},
    });

    my @offers = sort { $a->place->name cmp $b->place->name or $a->price <=> $b->price } (@daily, @weekly);

    my $out = '';
    $self->app->tt->process('day.html', {OFFERS => \@offers, date => $date}, \$out);

    return $out;
}

sub _next_date {
    my ($self, $date) = @_;

    my $daily = $self->app->rs('DailyOffer')->search(
        {date => {'>=' => $date->ymd('-')}},
        {order_by => {-asc => 'date'}},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    $daily = $self->app->rs('DailyOffer')->search(
        {},
        {order_by => {-desc => 'date'}},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    # database empty?
    return undef;
}


1;
