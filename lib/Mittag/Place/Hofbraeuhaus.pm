package Mittag::Place::Hofbraeuhaus;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id      { 4 }
sub file    { 'hofbraeuhaus.txt' }
sub name    { 'Hofbräuhaus' }
sub type    { 'web' }
sub address { 'Esplanade 6, 20354 Hamburg' }
sub geocode { [53.55759, 9.99149] }


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.hamburg-hofbraeuhaus.de/mittagstisch.htm';

    my $file = $self->file;
    $file =~ s/.txt$/.html/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->html2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    # trim, remove empty lines
    my @data = grep { $_ } map { _trim($_) } split /\n/, $data;

    # date range
    $self->_search('Mittagstisch', \@data);
    my @date = $self->_find(qr/^(\d\d)\.(\d\d)\.(\d\d\d\d) . \d\d\.\d\d\.\d\d\d\d/, \@data);
    my $week = join '-', reverse @date[0 .. 2];

    # correct Sunday to Friday
    my $date = DateTime->new(
        year  => $date[2],
        month => $date[1],
        day   => $date[0],
    );
    if ($date->dow == 7) {
        $date = $date->subtract(days => 2);
        $week = $date->ymd('-');
    }

    # meals
    $self->_search('Schnitzel-Variationen*:', \@data);

    my $meal = '';
    while (@data) {
        my $line = shift @data;
        if ($line =~ /(\d+,\d\d) ?€$/) {
            my $price = $1;
            $price =~ s/,/./;

            $importer->save_weekly(
                id    => $self->id,
                week  => $week,
                meal  => $meal,
                price => $price,
            );

            $meal = '';
            $self->_expect('***', shift @data);

            last if $data[0] eq 'Mittagskarte als Download (pdf-Datei)';
        }
        else {
            $line =~ s/^\s+//;
            $meal .= ' ' if $meal;
            $meal .= $line;
        }
    }

    $self->abort('end of meal (price) not found') unless @data;
}

###TODO### utility class
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
