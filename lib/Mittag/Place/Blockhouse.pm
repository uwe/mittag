package Mittag::Place::Blockhouse;

use utf8;
use strict;
use warnings;

use HTML::TableExtract;

use base qw/Mittag::Place/;


sub id      { 1 }
sub url     { 'http://www.block-house.de/block-house-restaurant-best-steaks-since-1968/block-house-qualitaet-ist-unsere-leidenschaft/block-house-lunch-time/' }
sub file    { 'block-house.html' }
sub name    { 'Block House' }
sub type    { 'web' }
sub address { 'Gänsemarkt Passage, 20354 Hamburg' }
sub geocode { [53.55535, 9.98941] }


sub download {
    my ($self, $downloader) = @_;

    $downloader->get_store($self->url, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my $te = HTML::TableExtract->new;
    $te->parse($data);

    my $table = $te->first_table_found or die 'no table found';

    my (@week1, @week2);
    foreach my $row ($table->rows) {
        push @week1, [$self->_trim_split($row->[0])];
        push @week2, [$self->_trim_split($row->[1])];
    }

    $self->_extract_week(\@week1, $importer);
    $self->_extract_week(\@week2, $importer);
}

sub _extract_week {
    my ($self, $data, $importer) = @_;

    # weekly offers
    my ($price) = $self->_find(qr/^Wählen Sie täglich zwischen unseren Wochengerichten für (\d+,\d\d) €$/, shift @$data);
    $price =~ s/,/./;

    # date is still missing ...
    my @weekly = ();
    foreach (1 .. 3) {
        my $meal = join ' ', @{shift @$data};
        push @weekly, [$meal, $price];
    }

    # daily offer
    foreach my $weekday ($self->_weekdays) {
        my @day = @{shift @$data};

        my $line = shift @day;
        unless ($line =~ /^$weekday \| (\d\d)\.(\d\d)\.(\d{4})$/) {
            $self->abort("date not found: $line");
        }

        my $date = "$3-$2-$1";

        # save weekly offers (only on Monday)
        if (@weekly) {
            while (my $weekly = shift @weekly) {
                $importer->save_weekly(
                    id    => $self->id,
                    week  => $date,
                    meal  => $weekly->[0],
                    price => $weekly->[1],
                );
            }
        }

        next if $day[0] eq '— Himmelfahrt —';
        next if $day[0] eq '— Pfingstmontag —';

        # price
        unless ($day[1] =~ /^(\d+,\d\d) €$/) {
            $self->abort("price not found: $day[1]");
        }
        my $price = $1;
        $price =~ s/,/./;

        my $meal = join(' ', $day[0], $day[2]);

        $importer->save(
            id    => $self->id,
            date  => $date,
            meal  => $meal,
            price => $price,
        );
    }
}


1;
