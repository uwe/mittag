package Mittag::Place::SoupFriends;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;


sub id      { 6 }
sub file    { 'soup-friends.txt' }
sub name    { 'Soup & Friends' }
sub type    { 'web' }
sub address { 'Valentinskamp 18, 20354 Hamburg' }
sub geocode { [53.55504, 9.98615] }


my @weekdays = qw(Mo Di Mi Do Fr);


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.soupandfriends.de/tageshits.html';

    my $file = $self->file;
    $file =~ s/.txt$/.html/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->html2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = grep { $_ } map { _trim($_) } split /\n/, $data;

    # without 'alt' texts
    @data = grep { $_ !~ /^Beschreibung: / } @data;

    my ($day, $month, $year) = $self->_find(qr/^(\d\d)\.(\d\d)\.(\d\d\d\d) . \d\d\.\d\d\.\d\d\d\d$/, \@data);

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    foreach my $weekday (@weekdays) {
        $self->_search($weekday, \@data);

        splice(@data, 0, 2);

        my $meal = $self->_meal(\@data);
        next unless $meal;
        next if $meal->[0] eq $meal->[1];

        $importer->save(
            id    => $self->id,
            date  => $date->ymd('-'),
            meal  => $meal->[0],
            price => $meal->[1],
        );

        shift @data;
        $meal = $self->_meal(\@data);

        $importer->save(
            id    => $self->id,
            date  => $date->ymd('-'),
            meal  => $meal->[0],
            price => $meal->[1],
        );
    } continue {
        $date = $date->add(days => 1);
    }
}

sub _meal {
    my ($self, $data) = @_;

    my @meal = ();
    while (@$data) {
        my $line = shift @$data;
        last if $line eq '€';
        push @meal, $line;
    }

    unless (@$data) {
        $self->abort('end of meal not found');
    }

    my $meal = join(' ', @meal);

    my $price1 = shift @$data;
    my $price2 = shift @$data;

    # holiday?
    if ($meal eq $price1) {
        return undef;
    }

    $price1 =~ s/,/./;
    $price2 =~ s/,/./;

    return [$meal, $price2];
}

sub _trim {
    my ($text) = @_;
    return unless $text;

    $text =~ s/\s/ /g;
    $text =~ s/^ +//;
    $text =~ s/ +$//;
    $text =~ s/ {2,}/ /g;

    return $text;
}


1;
