package Mittag::Place::Opera;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;


sub id      { 7 }
sub file    { '' }
sub name    { 'Opera' }
sub type    { 'mail' }
sub address { 'Dammtorstr. 7, 20354 Hamburg' }
sub geocode { [53.55689, 9.98755] }


my %MONTH = (
    Januar    =>  1,
    Februar   =>  2,
    März      =>  3,
    April     =>  4,
    Mai       =>  5,
    Juni      =>  6,
    Juli      =>  7,
    August    =>  8,
    September =>  9,
    Oktober   => 10,
    November  => 11,
    Dezember  => 12,
);


sub extract {
    my ($self, $mail, $importer) = @_;

    # check for correct mail
    return unless $mail->header('From') =~ /info\@ristorante-opera\.com/;

    # date
    return unless $mail->header('Subject') =~ /Mittagstisch [^ ]+ (\d+). ([^ ]+) (\d{4})/;

    my $day   = $1;
    my $month = $2;
    my $year  = $3;

    unless (exists $MONTH{$month}) {
        $self->abort("month '$month' unknown");
    }

    my $date = sprintf('%d-%02d-%02d', $year, $MONTH{$month}, $day);

    my $data = (($mail->parts)[0]->parts)[0]->body_str;
    $data =~ s/\r//g;
    $data =~ s/…/.../g;
    my @data = $self->_trim_split($data);

    # search for start
    while (@data) {
        my $line = shift @data;
        last if $line =~ /Auf Wunsch senden wir Ihnen die Mittagstischkarte/;
    }
    unless (@data) {
        $self->abort('Start not found');
    }

    while (@data) {
        my $line = shift @data;
        last if $line =~ /^Kaffee und Espresso/;
        last if $line =~ /^Halbe Portion Dessert/;

        if ($line !~ /€/) {
            # missing Euro sign?
            unless ($line =~ s/\.\.\s*(\d+,\d\d)$/..€$1/) {
                # run away line?
                if ($data[0] =~ /€/) {
                    $line .= ' ' . shift @data;
                } else {
                    $self->abort('Two lines without Euro sign');
                }
            }
        }

        my @meal  = split /\s*\.{2,}\s*/, $line;
        my $price = pop @meal;
        $price =~ s/€//;
        $price =~ s/\s//g;
        $price =~ s/,/./;

        unless ($price =~ /^\d{1,2}\.\d{2}$/) {
            $self->abort("Unknown price '$price'");
        }

        if (@meal > 2) {
            $self->abort("Meal too long: '@meal'");
        }

        my $meal = shift @meal;
        $meal .= ' ('.$meal[0].')' if @meal;

        $importer->save(
            id    => $self->id,
            date  => $date,
            meal  => $meal,
            price => $price,
        );
    }
    unless (@data) {
        $self->abort('End not found');
    }
}


1;
