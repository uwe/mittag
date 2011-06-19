package Mittag::Place::SchweinskeNeustadt;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;

use DateTime;


sub id      { 9 }
sub file    { 'schweinske-neustadt.txt' }
sub name    { 'Schweinske (Neustadt)' }
sub type    { 'web' }
sub address { 'Düsternstr. 1, 20355 Hamburg' }
sub geocode { [53.550851, 9.985092] }


my @weekdays = qw/Montag Dienstag Mittwoch Donnerstag Freitag/;


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.schweinske-mittagstisch.de/Speisekarten/Neustadt.pdf';

    my $file = $self->file;
    $file =~ s/\.txt$/.pdf/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->pdf2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = split /\n/, $data;

    $self->_expect('„Neustadt“', shift @data);

    # date range
    my ($day, $month, $year) = $self->_find(qr/^vom (\d\d)\.(\d\d)\. bis \d\d\.\d\d\.(\d{4})$/, \@data);

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    foreach my $day (@weekdays) {
        my $meal = shift @data;

        # remove weekday
        unless ($meal =~ s/^$day://) {
            $self->abort('weekday expected');
        }

        # collect all lines till price
        while (@data and $meal !~ /€/) {
            $meal .= ' ' . shift @data;
        }
        unless (@data) {
            $self->abort('end of meal not found');
        }

        unless ($meal =~ s/\s*(\d+,\d\d)\s*€$//) {
            $self->abort("price not found: '$meal'");
        }
        my $price = $1;
        $price =~ s/,/./;

        # cleanup foot notes
        $meal =~ s/([a-zA-Z]{3,})(\d(,\d)*)/$1/g;

        $importer->save(
            id    => $self->id,
            date  => $date->ymd('-'),
            meal  => $meal,
            price => $price,
        );

        $date = $date->add(days => 1);
    }
            
    ###TODO### second week?
}


1;
