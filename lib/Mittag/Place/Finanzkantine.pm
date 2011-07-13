package Mittag::Place::Finanzkantine;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id      { 2 }
sub file    { 'finanzkantine.txt' }
sub name    { 'Finanzkantine' }
sub type    { 'web' }
sub address { 'Gänsemarkt 36, 20354 Hamburg' }
sub geocode { [53.55527, 9.98767] }


my @weekdays = qw/Mo Di Mi Do Fr/;
my $regex    = qr/[IV]+\. (.+?) (\d+,\d\d) €(:? (\d+,\d\d) €)?$/; # no ^


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.kantine-der-finanzbehoerde.de/downloads/speisenkarte.pdf';

    my $file = $self->file;
    $file =~ s/\.txt$/.pdf/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->pdf2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = split /\n/, $data;

    $self->_search('Speisenkarte', \@data);

    my $line = shift @data;
    unless ($line =~ /^\d\d\.\d\d\. -? ?(\d\d)\.(\d\d)\.(\d{4})/) {
        die "date not found: $line";
    }
    my $date = DateTime->new(
        day   => $1,
        month => $2,
        year  => $3,
    )->subtract(days => 4);

    shift @data if $data[0] eq 'Kleine';

    $self->_find(qr/Portion$/, \@data);

    foreach my $weekday (@weekdays) {
        my @offer = ();

        unless ($data[0] =~ s/^$weekday\. //) {
            $self->abort("weekday '$weekday' not found: $data[0]");
        }

        if ($data[0] !~ /^$regex/ and $data[0] =~ /\b(Feiertag|Pfinstmontag)\b/) {
            shift @data;
            $date = $date->add(days => 1);
            next;
        }

        while (@data) {
            last unless $data[0] =~ /^$regex/;

            my $meal  = $1;
            my $price = $2;
            $price =~ s/,/./;

            shift @data;

            # continued meal?
            if ($data[0] !~ /$regex/ and
                $data[0] ne 'Liebe Gäste,' and
                $data[0] !~ /^(Mo|Di|Mi|Do|Fr)\. /
                ) {
                $meal .= ' ' . shift @data;
            }

            # cleanup foot notes
            $meal =~ s/²+³//g;

            $importer->save(
                id    => $self->id,
                date  => $date->ymd('-'),
                meal  => $meal,
                price => $price,
            );
        }

        unless (@data) {
            self->abort("unexpected end in weekday '$weekday'");
        }

        $date = $date->add(days => 1);
    }
}

1;
