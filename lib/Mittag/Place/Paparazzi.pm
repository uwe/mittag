package Mittag::Place::Paparazzi;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id      { 12 }
sub file    { 'paparazzi.txt' }
sub name    { 'Paparazzi' }
sub type    { 'web' }
sub address { 'Caffamacherreihe 1, 20350 Hamburg' }
sub geocode { [53.55421, 9.98444] }

sub url     { 'http://paparazzi-restaurant-hamburg.pace-berlin.de/wp-content/plugins/download-monitor/download.php?id=1' };


my @weekdays  = qw/Montag Dienstag Mittwoch Donnerstag Freitag/;


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

    my @data = grep { $_ } split /\n/, $data;

    my ($day, $month, $year) = $self->_find(qr/Speisenangebot vom (\d\d)\.(\d\d)\. bis \d\d\.\d\d\.(\d{4})/, \@data);

    # year is still 2010 :(
    $year = 2011 if $year == 2010;

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    # get starting positions for text
    my @pos;
    my $line = shift @data;
    my @headlines = grep { $_ } split / {3,}/, $line;
    $self->abort("Headlines not found: $line") unless $headlines[0] =~ /Tag$/;
    foreach my $headline (@headlines) {
        $headline =~ s/^ +//;
        $headline =~ s/ +$//;

        my $start = index($line, $headline);
        my $end   = $start + length $headline;
        push @pos, [$start, $end];
    }

    # expand positions
    my @copy;
    my $count = 0;
    while (@data) {
        my $line = shift @data;
        next unless $line;

        push @copy, $line;

        $count++ if $line =~ /\d,\d\d (?:€|EUR)/;
        last if $count == 5;

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
            foreach my $meal (@meal) {
                my $price = shift @price;
                $price =~ s/,/./;

                $importer->save(
                    id    => $self->id,
                    date  => $date->ymd('-'),
                    meal  => $self->_fix_meal($meal),
                    price => $price,
                    );
            }

            @meal = ();
            $date = $date->add(days => 1);
            next;
        }

        foreach my $i (1 .. 5) {
            my ($start, $end) = @{$pos[$i]};
            last if $start > length $line;

            $end = length $line if $end > length $line;
            $meal[$i - 1] .= substr($line, $start, $end - $start);
        }
    }
}

sub _fix_meal {
    my ($self, $meal) = @_;

    $meal =~ s/Leichte Küche//;
    $meal =~ s/Gutes aus der Region//;

    return $self->_trim($meal);
}


1;
