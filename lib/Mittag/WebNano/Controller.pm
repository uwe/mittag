package Mittag::WebNano::Controller;

use strict;
use warnings;

use base qw/WebNano::Controller/;

use DateTime;

use Mittag::Places;


sub redirect {
    my ($self, $url) = @_;

    my $res = $self->req->new_response;
    $res->redirect($url);
    return $res;
}

sub index_action {
    my ($self) = @_;

    my $today = DateTime->today;
    if ($today->dow > 5) {
        $today = $self->_next_date($today);

        # go back if no data
        $today = $self->_prev_date(DateTime->today) unless $today;
    }

    return $self->redirect('/day/' . $today->ymd('-'));
}

sub place_action {
    my ($self, $place_id) = @_;

    my $place = Mittag::Places->place_by_id($place_id);

    return $self->redirect('/places') unless $place;

    return $self->app->render('place.html', {place => $place});
}

sub places_action {
    my ($self) = @_;

    return $self->app->render('places.html');
}

sub day_action {
    my ($self, $input_date, $mobile) = @_;

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
        next_date => $self->_next_date($date->clone->add(     days => 1)) || undef,
    };

    my $template = 'day.html';
    if ($mobile) {
        $vars->{mobile} = 1;
        $template = 'mobile.html';
    }

    return $self->app->render($template, $vars);
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
