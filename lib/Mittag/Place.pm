package Mittag::Place;

# base class for places (restaurants)

use utf8;
use strict;
use warnings;

use base qw/Class::Accessor::Faster/;


__PACKAGE__->mk_accessors(qw/context/);


my %MONTH = (
    'Januar'    =>  1,
    'Februar'   =>  2,
    'März'      =>  3,
    'April'     =>  4,
    'Mai'       =>  5,
    'Juni'      =>  6,
    'Juli'      =>  7,
    'August'    =>  8,
    'September' =>  9,
    'Oktober'   => 10,
    'November'  => 11,
    'Dezember'  => 12,

    'Jan' =>  1, 'Feb' =>  2, 'Mär' =>  3, 'Apr' =>  4,
    'Mai' =>  5, 'Jun' =>  6, 'Jul' =>  7, 'Aug' =>  8,
    'Sep' =>  9, 'Okt' => 10, 'Nov' => 11, 'Dez' => 12,
);


sub disabled {}


sub _expect {
    my ($self, $text, $data, $start) = @_;

    if ($start) {
        # 1 - $data starts with $text (can be longer)
        if (index($data, $text)) {
            $self->abort("expected: '$text', found '$data'");
        }
    } else {
        if ($data ne $text) {
            $self->abort("expected: '$text', found: '$data'");
        }
    }
}

sub _search {
    my ($self, $text, $data) = @_;

    while (@$data) {
        my $line = shift @$data;
        return if $line eq $text;
    }

    $self->abort("text '$text' not found");
}

sub _find {
    my ($self, $regex, $data) = @_;

    while (@$data) {
        my $line = shift @$data;
        if ($line =~ $regex) {
            return ($1, $2, $3, $4, $5, $6); ###TODO###
        }
    }

    $self->abort("regex '$regex' did not match");
}

sub abort {
    my ($self, $message) = @_;

    die sprintf(
        '%s: %s',
        $self,
        $message,
    );
}

sub _trim {
    my ($self, $text) = @_;
    return unless $text;

    $text =~ s/\s/ /g;
    $text =~ s/^ +//;
    $text =~ s/ +$//;
    $text =~ s/ {2,}/ /g;

    return $text;
}

sub _trim_split {
    my ($self, $data) = @_;

    return grep { $_ } map { $self->_trim($_) } split /\n/, $data;
}

sub _from_month {
    my ($self, $month) = @_;

    return $MONTH{$month};
}

sub _weekdays {
    return qw/Montag Dienstag Mittwoch Donnerstag Freitag/;
}

sub _weekdays_short {
    return qw/Mo Di Mi Do Fr/;
}


1;
