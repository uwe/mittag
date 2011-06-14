package Mittag::Place::Schauspielhaus;

use utf8;
use strict;
use warnings;

use Encode ();
use HTML::TableExtract;

use base qw/Mittag::Place/;


sub id      { 5 }
sub file    { 'schauspielhaus.html' }
sub name    { 'Schauspielhaus' }
sub address { 'Kirchenallee 39, 20099 Hamburg' }
sub geocode { [53.5545378, 10.008363] }


my @headers = (
    qr/Montag/,
    qr/Dienstag/,
    qr/Mittwoch/,
    qr/Donnerstag/,
    qr/Freitag/,
);


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://diekantine.eu/index.php?action=menu&do=lunch';

    my $html = Encode::decode('windows-1252', $downloader->get($url));
    $downloader->store($html, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my $te = HTML::TableExtract->new(
        headers      => \@headers,
        keep_headers => 1,
    );
    $te->parse($data);

    my $table = $te->first_table_found or die 'no table found';

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
            die 'no date found';
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
