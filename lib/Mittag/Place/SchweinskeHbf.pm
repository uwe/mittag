package Mittag::Place::SchweinskeHbf;

###TODO### reuse SchweinskeNeustadt

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;

use DateTime;


sub id      { 8 }
sub file    { 'schweinske-hbf.txt' }
sub name    { 'Schweinske (Hbf)' }
sub type    { 'web' }
sub address { 'Glockengießerwall 8, 20095 Hamburg' }
sub geocode { [53.553215, 10.0054554] }


my @weekdays = qw/Montag Dienstag Mittwoch Donnerstag Freitag/;


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.schweinske-mittagstisch.de/newsletter.html';

    my $html = $downloader->get($url);

    return unless $html =~ m|<script language="javascript" src="(http://[^/]+/generate-js/[^\"]+)"|;
    my $javascript = $downloader->get($1);

    return unless $javascript =~ m|<a href=\\"(http:[^"]+)\\" title=\\"Schweinske Mittagstisch Hauptbahnhof|;
    $url = $1;
    $url =~ s/\\//g; # remove escaping

    my $file = $self->file;
    $file =~ s/\.txt$/.html/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->html2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = $self->_trim_split($data);

    # date range
    my ($day, $month, $year) = $self->_find(qr/^Ihr Mittagstisch vom (\d\d)\.(\d\d)\. bis \d\d\.\d\d\.(\d{2,4})$/, \@data);
    $year += 2000 if $year < 100;

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    my $line = shift @data;
    foreach my $day (@weekdays) {
        $self->_expect($day, $line);

        $line = shift @data;
        my $multi = 0;
        while ($line =~ s/^M \d: //) {
            my $meal = $line;

          again:
            unless ($meal =~ s/\s*€\s*(\d+,\d\d)$//) {
                $self->abort("price not found: $meal") if $multi;
                $multi = 1;
                $meal .= ' ' . shift @data;
                goto again;
            }

            my $price = $1;
            $price =~ s/,/./;

            $importer->save(
                id    => $self->id,
                date  => $date->ymd('-'),
                meal  => $meal,
                price => $price,
                );

            $line = shift @data;
            $multi = 0;
        }

        $date = $date->add(days => 1);
    }
}


1;
