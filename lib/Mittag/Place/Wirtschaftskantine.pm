package Mittag::Place::Wirtschaftskantine;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id      { 11 }
sub file    { 'wirtschaftskantine.txt' }
sub name    { 'Wirtschaftskantine' }
sub type    { 'web' }
sub address { 'Neuer Jungfernstieg 21, 20354 Hamburg' }
sub geocode { [] }


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.arbeitsgerichtskantine.de/save/wochenkarte_wk.pdf';

    my $file = $self->file;
    $file =~ s/.txt$/.pdf/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->pdf2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

}


1;
