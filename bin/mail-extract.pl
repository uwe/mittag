#!/usr/bin/perl

use strict;
use warnings;

use Email::MIME;
use File::Slurp  qw/read_file/;
use FindBin;
use Module::Find qw/useall/;

use lib $FindBin::Bin . '/../lib';
use Mittag::Config;
use Mittag::DB::Schema;
use Mittag::Importer;


my $config   = Mittag::Config->new($FindBin::Bin . '/..');
my $schema   = Mittag::DB::Schema->connect_with_config($config);
my $importer = Mittag::Importer->new({
    config => $config,
    schema => $schema,
});

my @places = grep { $_->type eq 'mail' } useall 'Mittag::Place';

if ($ARGV[0]) {
    @places = grep { /Mittag::Place::$ARGV[0]/ } @places;
}

foreach my $file (glob $config->{path_mail} . '*.txt') {
    my $data = read_file $file;
    my $mail = Email::MIME->new($data);

    foreach my $class (@places) {
        $class->extract($mail, $importer);
    }
}
