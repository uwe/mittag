package Mittag::Place::SoupCity;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id       { 13 }
sub url      { 'http://www.soupcity.de/aktuell/karte_st.html' }
sub file     { 'soupcity.txt' }
sub name     { 'Soup City' }
sub type     { 'web' }
sub address  { 'Steinstraße 17a
20095 Hamburg' }
sub phone    { }
sub email    { 'info@soupcity.de' }
sub homepage { 'http://www.soupcity.de/' }
sub geocode  { [53.54992, 10.00231] }


my @weekdays = qw/Montag Dienstag Mittwoch Donnerstag Freitag/;
my %month = (
    'Januar'    =>  1,
    'Februar'   =>  2,
    'März'      =>  3,
    'April'     =>  4,
    'Mai'       =>  5,
    'Juni'      =>  6,
    'Juli'      =>  7,
    'August'    =>  8,
    'September' =>  9,
    'Oktober'   => 10,
    'November'  => 11,
    'Dezember'  => 12,
);


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

    my ($day, $month, $year) = $self->_find(qr/^\d+\.(?: [^ ]+)? - (\d+)\. ([^ ]+) (\d{4})$/, \@data);

    # Friday to Monday
    my $date = DateTime->new(
        day   => $day,
        month => $month{$month},
        year  => $year,
    )->subtract(days => 4);

    foreach my $weekday (@weekdays) {
        $self->_search($weekday, \@data);

        # two soups per day
        foreach (1 .. 2) {
            my $meal = shift @data;
            my $price;
            while (my $line = shift @data) {
                if ($line =~ /^(?:€|EUR) (\d+,\d\d)$/) {
                    $price = $1;
                    $price =~ s/,/./g;
                    last;
                }
                $meal .= ' ' . $line;
            }

            unless ($price) {
                $self->abort('end of meal not found');
            }

            $importer->save(
                id    => $self->id,
                date  => $date->ymd('-'),
                meal  => $meal,
                price => $price,
            );
        }

        $date = $date->add(days => 1);
    }
}


1;
