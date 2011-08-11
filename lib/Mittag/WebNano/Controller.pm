package Mittag::WebNano::Controller;

use strict;
use warnings;

use base qw/WebNano::Controller/;

use DateTime;
use JSON::XS;

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

    my @offers = $self->_get_offers($date);

    unless (@offers) {
        my $next_date = $self->_next_date($date, 1);
        # if there is no future date, we try backwards
        $next_date ||= $self->_prev_date($date, 1);

        my $res = $self->req->new_response;
        $res->redirect('/day/' . $next_date->ymd('-'));
        return $res;
    }
    
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

sub rest_action {
    my ($self, $input_date) = @_;

    my @date = split /-/, $input_date;
    my $date = DateTime->new(
        year  => $date[0],
        month => $date[1],
        day   => $date[2],
    );

    # only allow narrow date range
    my $today = DateTime->today;
    my $delta = $today->delta_days($date)->days;
    if ($delta > 3) {
        return encode_json {};
    }

    my @offers = map {
        {
            place => $_->place->name,
            meal  => $_->name,
            price => $_->price,
        }
    } $self->_get_offers($date);

    my $prev_date = $self->_prev_date($date->clone->subtract(days => 1));
    my $next_date = $self->_next_date($date->clone->add(     days => 1));

    return encode_json {
        offers    => \@offers,
        prev_date => $prev_date->ymd('-'),
        next_date => $next_date->ymd('-'),
    };
}

# --------------------------------------------------------------------------------

# get daily and weekly offers (sorted by place and price)
sub _get_offers {
    my ($self, $date) = @_;

    my @daily  = $self->app->rs('DailyOffer')->search({date => $date->ymd('-')});

    return unless @daily;

    my @weekly = $self->app->rs('WeeklyOffer')->search({
        from_date => {'<=' => $date->ymd('-')},
        to_date   => {'>=' => $date->ymd('-')},
    });

    my @offers = sort { $a->place->name cmp $b->place->name or $a->price <=> $b->price } (@daily, @weekly);

    return @offers;
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
