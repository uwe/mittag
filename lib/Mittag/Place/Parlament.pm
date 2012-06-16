package Mittag::Place::Parlament;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;


sub id       { 17 }
sub url      { 'http://www.parlament-hamburg.de/pdf/Mittagskarte.pdf' }
sub file     { 'parlament.txt' }
sub name     { 'Parlament' }
sub type     { 'web' }
sub address  { 'Rathausmarkt 1
20095 Hamburg' }
sub phone    { '040/70383399' }
sub email    { 'gastro@parlament-hamburg.de' }
sub homepage { 'http://www.parlament-hamburg.de/' }
sub geocode  { [53.55074, 9.99206] }


sub download {
    my ($self, $downloader) = @_;

    my $file = $self->file;
    $file =~ s/\.txt$/.html/;
    $downloader->get_store($self->url, $file);

    my $txt = $downloader->pdf2txt($file, 1);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = $self->_trim_split($data);

    my ($day, $month) = $self->_find(qr/Montag,? (\d\d)\.\s*([^ ]+) bis Samstag/, \@data);

    $month = $self->_from_month($month);

    my $today = DateTime->today;
    my $year = $today->year;

    # special year end condition
    $year-- if $month == 12 and $today->month == 1;

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    shift @data;

    my $meal  = '';
    my $price = 0;
    while (my $line = shift @data) {
        if ($line =~ /Wählen Sie ein 0,2 l Softgetränk /) {
            $importer->save_weekly(
                id    => $self->id,
                week  => $date->ymd('-'),
                meal  => $meal,
                price => $price,
            );
            last;
        }

        if ($line =~ s/(\d+,\d\d) (?:€|EUR)//) {
            my $new_price = $1;
            $new_price =~ s/,/./;

            # save previous meal
            if ($meal) {
                $importer->save_weekly(
                    id    => $self->id,
                    week  => $date->ymd('-'),
                    meal  => $meal,
                    price => $price,
                );
            }

            $price = $new_price;
            $meal  = $self->_trim($line);
        }
        else {
            $meal .= ' ' . $line;
        }
    }
}


1;
