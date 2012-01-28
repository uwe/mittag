package Mittag::Web::Day;

use Mojo::Base 'Mojolicious::Controller';

use DateTime;


sub date {
    my ($self) = @_;

    my $date = eval {
        my @date = split /-/, $self->param('date') || '';
        DateTime->new(
            year  => $date[0],
            month => $date[1],
            day   => $date[2],
        );
    };
    unless ($date) {
        my $today = DateTime->today;
        if ($today->dow > 5) {
            $today = $self->_next_date($today);

            # go back if no data
            $today = $self->_prev_date(DateTime->today) unless $today;
        }

        $date = $today;
    }

    my @offers = $self->_get_offers($date);

    unless (@offers) {
        my $next_date = $self->_next_date($date, 1);
        # if there is no future date, we try backwards
        $next_date ||= $self->_prev_date($date, 1);

        my $res = $self->req->new_response;
        $res->redirect('/day/' . $next_date->ymd('-'));
        return $res;
    }

    $self->stash(
        OFFERS    => \@offers,
        date      => $date,
        prev_date => $self->_prev_date($date->clone->subtract(days => 1)) || undef,
        next_date => $self->_next_date($date->clone->add(     days => 1)) || undef,
    );
}

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
