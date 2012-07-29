package Mittag::Place::Finanzkantine;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id       { 2 }
sub url      { 'http://www.kantine-der-finanzbehoerde.de/downloads/speisenkarte.pdf' }
sub file     { 'finanzkantine.txt' }
sub name     { 'Finanzkantine' }
sub type     { 'web' }
sub address  { 'Gänsemarkt 36
20354 Hamburg' }
sub phone    { '040/343185' }
sub email    { 'luziangraun@aol.com' }
sub homepage { 'http://www.kantine-der-finanzbehoerde.de/' }
sub geocode  { [53.55527, 9.98767] }


my $regex    = qr/[IV]+\. (.+?) (\d+,\d\d) €(:? (\d+,\d\d) €)?$/; # no ^


sub download {
    my ($self, $downloader) = @_;

    my $file = $self->file;
    $file =~ s/\.txt$/.pdf/;
    $downloader->get_store($self->url, $file);

    my $txt = $downloader->pdf2txt($file, 1);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = $self->_trim_split($data);

    my $date;
    while (my $line = shift @data) {
        if ($line =~ /^\d\d\. ?\d\d\. -? ?(\d\d)\. ?(\d\d)\. ?(\d{4})/) {
            $date = DateTime->new(
                day   => $1,
                month => $2,
                year  => $3,
            )->subtract(days => 4);
            last;
        }
    }
    unless ($date) {
        die "date not found.";
    }

    shift @data if $data[0] =~ /Kleine$/;
    shift @data if $data[0] eq 'Portion';

    foreach my $weekday ($self->_weekdays_short) {
        my @offer = ();

        unless ($data[0] =~ s/^$weekday\. //) {
            $self->abort("weekday '$weekday' not found: $data[0]");
        }

        if ($data[0] !~ /^$regex/ and $data[0] =~ /\b(Feiertag|Pfinstmontag|Maifeiertag)\b/) {
            shift @data;
            shift @data if $data[0] =~ /(Tag der Arbeit)/;
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
