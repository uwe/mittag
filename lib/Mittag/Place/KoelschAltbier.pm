package Mittag::Place::KoelschAltbier;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id      { 10 }
sub url     { 'http://www.koelsch-city.de/wp/?page_id=127' }
sub file    { 'koelsch-altbier.txt' }
sub name    { 'Kölsch und Altbierhaus' }
sub type    { 'web' }
sub address { 'Valentinskamp 89, 20354 Hamburg' }
sub geocode { [53.5558143, 9.9850255] }


my @weekdays = qw/MONTAG DIENSTAG MITTWOCH DONNERSTAG FREITAG/;


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

    my ($day, $month, $year) = $self->_find(qr/^vom (\d\d)\.(\d\d)\.(\d{4}) bis (\d\d)\.(\d\d)\.(\d{4})/, \@data);

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    # weekly offers
    foreach my $idx (qw/A B/) {
        my $line = shift @data;

        unless ($line =~ /^Tipp $idx (.+) (?:€|EUR) ([0-9.]+)$/) {
            $self->abort("Weekly offer $idx not found: $line");
        }

        $importer->save_weekly(
            id    => $self->id,
            week  => $date->ymd('-'),
            meal  => $1,
            price => $2,
        );
    }

    # daily offers
    foreach my $weekday (@weekdays) {
        my $line = shift @data;

        unless ($line =~ /^$weekday (.+) (?:€|EUR) ([0-9.]+)$/) {
            $self->abort("Daily offer for $weekday not found: $line");
        }

        $importer->save(
            id    => $self->id,
            date  => $date->ymd('-'),
            meal  => $1,
            price => $2,
        );

        $date = $date->add(days => 1);
    }
}


1;
