package Mittag::Place::Wirtschaftskantine;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id      { 11 }
sub url     { 'http://www.arbeitsgerichtskantine.de/save/wochenkarte_wk.pdf' }
sub file    { 'wirtschaftskantine.txt' }
sub name    { 'Wirtschaftskantine' }
sub type    { 'web' }
sub address { 'Neuer Jungfernstieg 21, 20354 Hamburg' }
sub geocode { [53.55703, 9.99248] }


my @weekdays = qw/Montag Dienstag Mittwoch Donnerstag Freitag/;


sub download {
    my ($self, $downloader) = @_;

    my $file = $self->file;
    $file =~ s/.txt$/.pdf/;
    $downloader->get_store($self->url, $file);

    my $txt = $downloader->pdf2txt($file, 1);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = split /\n/, $data;

    my ($day, $month, $year) = $self->_find(qr/Wochenplan vom (\d\d)\.(\d\d)\.(\d{4}) bis (\d\d)\.(\d\d)\.(\d{4})/, \@data);

    my $start_date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    # get starting positions for text
    my @pos;
    my $line = shift @data;
    foreach my $weekday (@weekdays) {
        my $start = index($line, $weekday);
        my $end   = $start + length $weekday;
        push @pos, [$start, $end];
    }

    # expand positions
    my @copy;
    my $count = 0;
    while (@data) {
        my $line = shift @data;
        next unless $line;

        push @copy, $line;

        $count++ if $line =~ /€/;
        last if $count == 3;

        foreach my $pos (@pos) {
            my ($start, $end) = @$pos;
            next if $start >= length $line;

          go_left:
            while ($start > 0 && substr($line, $start, 1) ne ' ') {
                $start--;
            }
            if ($start > 0 && substr($line, $start - 1, 1) ne ' ') {
                $start--;
                goto go_left;
            }

          go_right:
            while ($end < length $line && substr($line, $end - 1, 1) ne ' ') {
                $end++;
            }
            if ($end < length $line && substr($line, $end, 1) ne ' ') {
                $end++;
                goto go_right;
            }

            # update boundaries
            $pos->[0] = $start;
            $pos->[1] = $end;
        }
    }

    # extract text
    my @meal;
    foreach my $line (@copy) {
        if ($line =~ /([0-9,]+)[ €]+([0-9,]+)[ €]+([0-9,]+)[ €]+([0-9,]+)[ €]+([0-9,]+)/) {
            my @price = ($1, $2, $3, $4, $5);
            my $date = $start_date->clone;
            foreach my $meal (@meal) {
                my $price = shift @price;
                $price =~ s/,/./;

                $importer->save(
                    id    => $self->id,
                    date  => $date->ymd('-'),
                    meal  => $self->_trim($meal),
                    price => $price,
                );

                $date = $date->add(days => 1);
            }

            @meal = ();
            next;
        }

        foreach my $i (0 .. 4) {
            my ($start, $end) = @{$pos[$i]};
            last if $start > length $line;

            $end = length $line if $end > length $line;
            $meal[$i] .= substr($line, $start, $end - $start);
        }
    }
}


1;
