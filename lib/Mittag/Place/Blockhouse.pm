package Mittag::Place::Blockhouse;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;


sub id      { 1 }
sub file    { 'block-house.txt' }
sub name    { 'Block House' }
sub type    { 'web' }
sub address { 'Gänsemarkt Passage, 20354 Hamburg' }
sub geocode { [53.55535, 9.98941] }


my @weekdays = qw(Montag Dienstag Mittwoch Donnerstag Freitag);


sub download {
    my ($self, $downloader) = @_;

    my $url = 'http://www.block-house.de/block-house-restaurant-best-steaks-since-1968/block-house-qualitaet-ist-unsere-leidenschaft/block-house-lunch-time/'; # SEO gone mad :)

    my $file = $self->file; $file =~ s/\.txt$/.html/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->html2txt($file);

    # remove empty lines
    $txt =~ s/\n{2,}/\n/gms;

    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = grep { $_ } split /\n/, $data;

    # two weeks
    $self->_extract_week(\@data, $importer);
    $self->_extract_week(\@data, $importer);
}

sub _extract_week {
    my ($self, $data, $importer) = @_;

    # weekly offers
    my ($price) = $self->_find(qr/^Wählen Sie täglich zwischen unseren Wochengerichten für (\d+,\d\d) €$/, $data);
    $price =~ s/,/./;

    # date is still missing ...
    my @weekly = ();
    foreach (1 .. 3) {
        my $meal = join(' ', splice @$data, 0, 2);
        push @weekly, [$meal, $price];
    }

    # daily offer
    foreach my $weekday (@weekdays) {
        my $line = shift @$data;
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

        my $meal = shift @$data;

        next if $meal eq '— Himmelfahrt —';
        next if $meal eq '— Pfingstmontag —';

        $line = shift @$data;
        unless ($line =~ /^(\d+,\d\d) €$/) {
            $self->abort("price not found: $line");
        }
        my $price = $1;
        $price =~ s/,/./;

        unless (
            $data->[0] =~ /^(Montag|Dienstag|Mittwoch|Donnerstag|Freitag) \| (\d\d)\.(\d\d)\.(\d{4})$/ or
            $data->[0] =~ /^Wählen Sie täglich zwischen unseren Wochengerichten für (\d+,\d\d) €$/ or
            $data->[0] eq 'Hauptspeisekarte'
            ) {
            $meal .= ' ' . shift @$data;
        }

        $importer->save(
            id    => $self->id,
            date  => $date,
            meal  => $meal,
            price => $price,
        );
    }
}


1;
