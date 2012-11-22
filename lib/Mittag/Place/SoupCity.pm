package Mittag::Place::SoupCity;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id       { 13 }
sub url      { 'http://www.soupcity.de/mittagstisch/steinstrasse' }
sub file     { 'soupcity.txt' }
sub name     { 'Soup City' }
sub type     { 'web' }
sub address  { 'Steinstraße 17a
20095 Hamburg' }
sub phone    { }
sub email    { 'info@soupcity.de' }
sub homepage { 'http://www.soupcity.de/' }
sub geocode  { [53.54992, 10.00231] }


sub download {
    my ($self, $downloader) = @_;

    my $file = $self->file;
    $file =~ s/.txt$/.html/;
    $downloader->get_store($self->url, $file);

    my $txt = $downloader->html2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = $self->_trim_split($data);

    my ($day, $month, $year) = $self->_find(qr/\d+\.(?: [^ ]+)? - (\d+)\. ([^ ]+) (\d{4})$/, \@data);

    # Friday to Monday
    my $date = DateTime->new(
        day   => $day,
        month => $self->_from_month($month),
        year  => $year,
    )->subtract(days => 4);

    $self->_search('Tagessuppen', \@data);

    my @daily_meals;
    foreach (1 .. 5) {
        # two soups per day
        foreach (1 .. 2) {
            push @daily_meals, { date => $date->ymd('-'), $self->_extract(\@data) };
        }

        $date = $date->add(days => 1);
    }

    $importer->save(%$_) foreach @daily_meals;

    $self->_search('Wochensuppen', \@data);

    my $week = $date->truncate(to => 'week');
    my @weekly_meals;
    until ($data[0] eq 'Newsletter') {
        push @weekly_meals, { week => $week->ymd('-'), $self->_extract(\@data) };
    }

    $importer->save_weekly(%$_) foreach @weekly_meals;
}

sub _extract {
    my ($self, $data) = @_;

    my $meal = shift @$data;
    my $price;
    while (my $line = shift @$data) {
        if ($line =~ /^(?:€|EUR) (\d+,\d\d)$/) {
            $price = $1;
            $price =~ s/,/./g;
            last;
        }
        $meal .= ' ' . $line;
    }

    if ($data->[0] !~ /^(?:€|EUR) (\d+,\d\d)$/) {
        # extra line
        $meal .= ' ' . shift @$data;
    }

    unless ($price) {
        $self->abort('end of meal not found');
    }

    return (
        id    => $self->id,
        meal  => $meal,
        price => $price,
    );
}

1;
