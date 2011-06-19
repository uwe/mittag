package Mittag::Place::Gerichtskantine;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;


sub id      { 3 }
sub file    { 'gerichtskantine.txt' }
sub name    { 'Gerichtskantine' }
sub type    { 'web' }
sub address { 'Sievekingplatz 1, 20355 Hamburg' }
sub geocode { [53.5561, 9.97656] }


my @weekdays  = qw/Montag Dienstag Mittwoch Donnerstag Freitag/;
my @mealtypes = ('Stammessen', 'Leichte Küche', 'Vegetarisch');
my @holidays  = qw/wir wünschen einen schönen feiertag/;


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://diekantinen.de/index.php?sid=39&id=328';

    my $file = $self->file;
    $file =~ s/\.txt$/.html/;
    my $html = $downloader->get($url);
    $downloader->store($html, $file);

    # find URL for PDF
    unless ($html =~ /<a href="([^"]+)" [^>]+>Wochenspeiseplan</) {
        die 'URL for PDF not found';
    }

    $url = 'http://diekantinen.de/' . $1;

    $file = $self->file;
    $file =~ s/\.txt$/.pdf/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->pdf2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = split /\n/, $data;
    splice(@data, 0, 4);

    my @dates = ();

    foreach my $day (@weekdays) {
        my $line = shift @data;
        if ($line eq $day) {
            push @dates, _date(shift @data);
        } else {
            # holiday?
            warn "'$line' interpreted as holiday";
            shift @data;
            push @dates, undef;
        }
    }

    # skip soup
    splice(@data, 0, 15);

    foreach my $type (@mealtypes) {
        $self->_expect($type, shift @data, 1);

        my $holiday_before = 0;
        foreach my $date (@dates) {
            # holiday?
            unless ($date) {
                $holiday_before = 1;
                next;
            }

            my ($meal, $price) = _meal(\@data);

            # correct meal?
            if ($holiday_before) {
                $meal =~ s/^$_ // foreach (@holidays);
            }

            $importer->save(
                id    => $self->id,
                date  => $date,
                meal  => $meal,
                price => $price,
            );

            $holiday_before = 0;
        }
    }
}

sub _date {
    my ($date) = @_;

    if ($date =~ /^(\d\d)\.(\d\d)\.(\d\d\d\d)$/) {
        return join('-', $3, $2, $1);
    }

    die "wrong date format: '$date'";
}

sub _meal {
    my ($data) = @_;

    my $meal = '';

    while (@$data) {
        my $line = shift @$data;
        if ($line =~ /^(\d,\d\d) €$/) {
            my $price = $1;
            $price =~ s/,/./;
            return ($meal, $price);
        }
        $meal .= ' ' if $meal;
        $meal .= $line;
    }

    die 'end of meal (price) not found';
}


1;
