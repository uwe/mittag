package Mittag::Place;

# base class for places (restaurants)

use strict;
use warnings;

use base qw/Class::Accessor::Faster/;

use Data::Dump qw//;


__PACKAGE__->mk_accessors(qw/context/);


sub _expect {
    my ($self, $text, $data) = @_;

    if ($data ne $text) {
        die "expected: '$text', found: '$data'";
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

    die $message; ###TODO###, Data::Dump::dump $self->context;
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


1;
