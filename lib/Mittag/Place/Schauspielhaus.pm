package Mittag::Place::Schauspielhaus;

use utf8;
use strict;
use warnings;

use Encode ();
use HTML::TableExtract;

use base qw/Mittag::Place/;


sub id        { 5 }
sub url       { 'http://diekantine.eu/index.php?action=menu&do=lunch' }
sub file      { 'schauspielhaus.html' }
sub name      { 'Schauspielhaus' }
sub type      { 'web' }
sub address   { 'Gastronomie im Deutschen Schauspielhaus Hamburg
Kirchenallee 39
20099 Hamburg' }
sub phone     { '040/24871273' }
sub email     { }
sub homepage  { 'http://diekantine.eu/' }
sub geocode   { [53.5545378, 10.008363] }


sub download {
    my ($self, $downloader) = @_;

    my $html = Encode::decode('windows-1252', $downloader->get($self->url));
    $downloader->store($html, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my $te = HTML::TableExtract->new(
        headers      => [ map { qr/$_/ } $self->_weekdays ],
        keep_headers => 1,
    );
    $te->parse($data);

    my $table = $te->first_table_found or $self->abort('no table found.');

    my @days;
    foreach my $row ($table->rows) {
        foreach my $i (0 .. 4) {
            next unless $row->[$i];

            my $meal = _clean($row->[$i]);
            next unless $meal;

            push @{$days[$i]}, $meal;
        }
    }

    foreach my $i (0 .. 4) {
        my $day = shift @{$days[$i]};
        unless ($day =~ /, (\d\d)\.(\d\d)\.(\d\d)$/) {
            $self->abort("no date found: $day");
        }
        my $date = "20$3-$2-$1";

        next if $days[$i][0] eq 'Feiertag';

        foreach (@{$days[$i]}) {
            $importer->save(
                id    => $self->id,
                date  => $date,
                meal  => $_->[0],
                price => $_->[1],
            );
        }
    }
}

sub _clean {
    my ($text) = @_;

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    if ($text =~ s/ für ([0-9,]+)€$//) {
        my $price = $1;
        $price =~ s/,/./;
        return [$text, $price];
    }

    return $text;
}


1;
