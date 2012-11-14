package Mittag::Place::Karlsons;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id       { 19 }
sub url      { 'http://www.karlsons.de/lunches' }
sub file     { 'karlsons.txt' }
sub name     { 'Karlsons' }
sub type     { 'web' }
sub address  { "Alter Steinweg 10\n20149 Hamburg" }
sub phone    { '040/52598233' }
sub email    { 'mail@karlsons.de' }
sub homepage { 'http://www.karlsons.de/' }
sub geocode  { [53.550456, 9.982109] }


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

    my ($day, $month, $year)
        = $self->_find(qr/^Wochenkarte \d\d\.\d\d\ - (\d\d)\.(\d\d)\.(\d{4})/, \@data);
    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    )->subtract(days => 4);

    $self->_search('Mittagsgerichte', \@data);

    while (@data) {
        my ($meal, $price) = splice @data, 0, 2;
        last if $meal =~ /^Köttbullar/; # regular meals

        s/\s*€//, s/,/./ for $price;
        unless ($price =~ /^\d{1,2}\.\d{2}$/) {
            $self->abort("Unknown price '$price'");
        }

        $importer->save_weekly(
            id    => $self->id,
            week  => $date->ymd('-'),
            meal  => $meal,
            price => $price,
        );
    }
}

1;
