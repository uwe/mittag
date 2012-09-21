package Mittag::Place::Leopolds;

use utf8;
use strict;
use warnings;

use DateTime;
use HTML::TableExtract;

use base qw/Mittag::Place/;


sub id       { 14 }
sub url      { 'http://www.leopolds-wirtshaus.de/pages/mittagskarte' }
sub file     { 'leopolds.html' }
sub name     { 'Leopold\'s' }
sub type     { 'web' }
sub address  { 'Colonnaden 3
20354 Hamburg' }
sub phone    { '040/35710209' }
sub email    { 'info@leopolds-wirtshaus.de' }
sub homepage { 'http://www.leopolds-wirtshaus.de/'}
sub geocode  { [53.55495, 9.99042] }


sub days {
    return (
        ['Montag',     0, 0, 2],
        ['Dienstag',   3, 0, 2],
        ['Mittwoch',   0, 3, 6],
        ['Donnerstag', 3, 3, 6],
        ['Freitag',    6, 1, 4],
    );
}


sub download {
    my ($self, $downloader) = @_;

    $downloader->get_store($self->url, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my $te = HTML::TableExtract->new;
    $te->parse($data);

    my $table = $te->first_table_found or $self->abort('no table found.');
    my @rows  = $table->rows;

    # raw HTML for detecting main course
    $te = HTML::TableExtract->new(keep_html => 1);
    $te->parse($data);

    $table = $te->first_table_found or $self->abort('no table found (#2).');
    my @html_rows = $table->rows;

    foreach my $day ($self->days) {
        my ($weekday, $x, $y, $yp) = @$day;

        # weekday and date
        my ($day, $month) = $self->_find(qr/$weekday, +(\d+)\. ([^ ]+)/, [$rows[$x][$y]]);
        ###TODO### around New Year
        my $date = DateTime->new(
            day   => $day,
            month => $self->_from_month($month),
            year  => DateTime->today->year,
        );

        my $meal  = do {
            if ($html_rows[$x + 1][$y] =~ /^<strong>/) {
                $rows[$x + 1][$y];
            }
            elsif ($html_rows[$x + 2][$y] =~ /^<strong>/) {
                $rows[$x + 2][$y];
            }
            else {
                $rows[$x + 1][$y] . ' ' . $rows[$x + 2][$y];
            }
        };
        $meal =~ s/ \*$//;
        $meal =~ s/^\* //;

        next if $meal =~ /\bFeiertag\b/;

        my $price = $rows[$x + 1][$yp];
        $price =~ s/\s//g;
        $price =~ s/,/./;

        $importer->save(
            id    => $self->id,
            date  => $date->ymd('-'),
            meal  => $self->_trim($meal),
            price => $price,
        );
    }
}


1;
