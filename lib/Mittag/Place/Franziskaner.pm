package Mittag::Place::Franziskaner;

use utf8;
use strict;
use warnings;

use DateTime;
use HTML::TableExtract;

use base qw/Mittag::Place/;


sub id       { 16 }
sub url      { 'http://www.restaurant-franziskaner.de/de/mittag.htm' }
sub file     { 'franziskaner.html' }
sub name     { 'Franziskaner' }
sub type     { 'web' }
sub address  { 'Große Theaterstr. 9
20354 Hamburg' }
sub phone    { '040/345756' }
sub email    { 'info@restaurant-franziskaner.de' }
sub homepage { 'http://www.restaurant-franziskaner.de/' }
sub geocode  { [53.55637, 9.9907] }


sub download {
    my ($self, $downloader) = @_;

    $downloader->get_store($self->url, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    # extract date
    my $te = HTML::TableExtract->new(depth => 1, count => 3);
    $te->parse($data);

    my $table = $te->first_table_found or $self->abort('table (1,3) not found.');
    my $text = $table->cell(0, 1);

    unless ($text =~ /vom (\d{1,2})\.(?: [^ ]+)? bis (\d{1,2})\. ?([^ ]+) (\d{4}) 11.30 bis 15.00 Uhr/) {
        $self->abort("Date not found: $text");
    }

    # Friday (usually)
    my $date = DateTime->new(
        day   => $2,
        month => $self->_from_month($3),
        year  => $4,
    );
    # make it Monday
    $date = $date->subtract(days => $date->dow - 1);

    $te = HTML::TableExtract->new(depth => 2, count => 1);
    $te->parse($data);

    $table = $te->first_table_found or $self->abort('table (2,1) not found.');
    my @rows = $table->rows;

    foreach my $weekday ($self->_weekdays) {
        my $row = shift @rows;
        if ($self->_trim($row->[0]) ne $weekday) {
            $self->abort("Weekday not found. Expected: $weekday. Got: '$row->[0]'");
        }

        my $meal  = $self->_trim($row->[1]);
        my $price = $self->_trim($row->[3]);
        $price =~ s/,/./;

        $importer->save(
            id    => $self->id,
            date  => $date->ymd('-'),
            meal  => $meal,
            price => $price,
        );

        $date = $date->add(days => 1);
    }
}


1;
