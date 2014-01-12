package Mittag::Place::LOsteria;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id       { 21 }
sub url      { 'http://losteria.de/?uri=de-wochenmenue' }
sub file     { 'losteria.txt' }
sub name     { 'L\'Osteria' }
sub type     { 'web' }
sub address  { "Dammtorstraße 12\n20354 Hamburg" }
sub phone    { '040/34106788' }
sub email    { 'hamburg@losteria.de' }
sub homepage { 'http://www.losteria.de/' }
sub geocode  { [53.557136, 9.988353] }


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

    my $date = DateTime->now->truncate(to => 'week');

    $self->_search('Bei uns gibt es jede Woche etwas besonderes', \@data);

    my $count = 0;

    MEAL:
    while (@data) {
        my ($meal, $description) = splice @data, 0, 2;

        last MEAL if $meal !~ /(.*)(\d{1,2},\d{2})\s*€/;
        $meal     = $1;
        my $price = $2;

        s/,/./ for $price;

        if ($description =~ s/^Mit\b/mit/) {
            $description = "$meal ($description)";
        }

        $importer->save_weekly(
            id    => $self->id,
            week  => $date->ymd('-'),
            meal  => $description,
            price => $price,
        );
        $count++;
    }

    $self->abort('No meals found') if !$count;
}

1;
