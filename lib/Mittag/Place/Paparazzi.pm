package Mittag::Place::Paparazzi;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id       { 12 }
sub url      { 'http://paparazzi-restaurant-hamburg.pace-berlin.de/wp-content/plugins/download-monitor/download.php?id=1' };
sub file     { 'paparazzi.txt' }
sub name     { 'Paparazzi' }
sub type     { 'web' }
sub address  { 'Caffamacherreihe 1
20350 Hamburg' }
sub phone    { '040/34722540' }
sub email    { 'info@paparazzi-restaurant-hamburg.de' }
sub homepage { 'http://paparazzi-restaurant-hamburg.de/' }
sub geocode  { [53.55421, 9.98444] }


sub download {
    my ($self, $downloader) = @_;

    my $file = $self->file;
    $file =~ s/.txt$/.pdf/;
    $downloader->get_store($self->url, $file);

    my $txt = $downloader->pdf2txt($file, 1);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = grep { $_ } split /\n/, $data;

    foreach my $weekday ($self->_weekdays) {
        my ($day, $month, $year) = $self->_find(qr/^$weekday, (\d{1,2})\.(\d{1,2})\.(\d{2,4})$/, \@data);
        my $date = DateTime->new(
            day   => $day,
            month => $month,
            year  => $year,
        );

        next if $data[0] =~ /Heute geschlossen/;

        foreach (1..5) {
            my $meal = shift @data;
            next if $meal =~ /(iPad.Gericht nach Wahl|2 Gänge Axel-Springer Menü)/;

            unless ($meal =~ s/\s*(\d+,\d\d)\s*(?:€|EUR)$//) {
                $self->abort("price not found: $meal");
            }

            my $price = $1;
            $price =~ s/,/./;

            $importer->save(
                id    => $self->id,
                date  => $date->ymd('-'),
                meal  => $meal,
                price => $price,
            );
        }
    }
}


1;
