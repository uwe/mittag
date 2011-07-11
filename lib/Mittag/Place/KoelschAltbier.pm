package Mittag::Place::KoelschAltbier;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id      { 10 }
sub file    { 'koelsch-altbier.txt' }
sub name    { 'Kölsch und Altbierhaus' }
sub type    { 'web' }
sub address { 'Valentinskamp 89, 20354 Hamburg' }
sub geocode { [] }


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.koelsch-city.de/wp/?page_id=127';

    my $file = $self->file;
    $file =~ s/.txt$/.html/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->html2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

}


1;
