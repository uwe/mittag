package Mittag::Place::SchweinskeHbf;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;

use DateTime;


sub id      { 8 }
sub file    { 'schweinske-hbf.txt' }
sub name    { 'Schweinske (Hbf)' }
sub type    { 'web' }
sub address { 'Glockengießerwall 8, 20095 Hamburg' }
sub geocode { [53.553215, 10.0054554] }


my @weekdays = qw/Montag Dienstag Mittwoch Donnerstag Freitag/;


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.schweinske-mittagstisch.de/Speisekarten/HHHbf.pdf';

    my $file = $self->file;
    $file =~ s/\.txt$/.pdf/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->pdf2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = split /\n/, $data;

    # date range
    my ($day, $month, $year) = $self->_find(qr/^vom (\d\d)\.(\d\d)\. bis \d\d\.\d\d\.(\d{4})$/, \@data);

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    shift @data;

    foreach my $day (@weekdays) {
        $self->_expect($day, shift @data);
        while ($data[0] =~ /^M \d: ([^€]+)€\s*(\d+,\d\d)$/) {
            my $meal  = $1;
            my $price = $2;
            $meal  =~ s/\s+$//;
            $price =~ s/,/./;

            $importer->save(
                id    => $self->id,
                date  => $date->ymd('-'),
                meal  => $meal,
                price => $price,
            );

            shift @data;
        }
        $date = $date->add(days => 1);
    }
            
    ###TODO### second week?
}


1;
