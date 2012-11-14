package Mittag::Place::Studierendenhaus;

use utf8;
use strict;
use warnings;

use DateTime;

use base qw/Mittag::Place/;


sub id       { 20 }
sub url      { 'http://speiseplan.studwerk.uptrade.de/index.php/de/cafeteria/show/id/310' }
sub file     { 'studierendenhaus.html' }
sub name     { 'Mensa Studierendenhaus' }
sub type     { 'web' }
sub address  { "Von-Melle-Park 2\n20146 Hamburg" }
sub phone    { }
sub email    { }
sub homepage { 'http://www.studierendenwerk-hamburg.de/studierendenwerk/de/essen/speiseplaene/' }
sub geocode  { [53.565675, 9.986207] }


sub download {
    my ($self, $downloader) = @_;

    my $html = $downloader->get($self->url);

    # find menu URL
    unless ($html =~ /<a [^>]*href="([^"]+)"[^>]*>\s*Diese Woche\s*</) {
        die 'Menu URL not found';
    }

    my $url = 'http://speiseplan.studwerk.uptrade.de' . $1;

    $downloader->get_store($url, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my $te = HTML::TableExtract->new;
    $te->parse($data);

    my $table = $te->first_table_found or $self->abort('no table found.');
    my @rows  = $table->rows;

    my ($day, $month, $year) = $rows[0][0] =~ /Wochenplan:\s*(\d\d)\.(\d\d)\.(\d{4}) -/
        or $self->abort('Date not found');
    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    COLUMN:
    foreach my $col (1 .. 5) {
        my $wday     = $self->_trim($rows[0][$col]);
        my $expected = ($self->_weekdays)[$col-1];
        if ($wday ne $expected) {
            $self->abort("Weekday '$expected' not found");
        }

        ROW:
        foreach my $row (1 .. $#rows) {
            my $content = $rows[$row][$col];
            next ROW if $content !~ /\S/;

            my @lines = $self->_trim_split($content);

            MEAL:
            while (@lines) {
                my ($meal, $price) = splice @lines, 0, 2;

                $meal =~ s/\((?:\d+, )*\d+\)//g;
                $meal = $self->_trim($meal);

                $price =~ /^(\d,\d\d) €/
                    or $self->abort("Price for '$meal' not found");
                $price = $1;
                $price =~ tr/,/./;

                $importer->save(
                    id    => $self->id,
                    date  => $date->ymd('-'),
                    meal  => $meal,
                    price => $price,
                );
            }
        }

        $date = $date->add(days => 1);
    }
}

1;
