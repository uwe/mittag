#!/usr/bin/perl

use strict;
use warnings;

use Encode       qw/decode/;
use File::Slurp  qw/read_file/;
use FindBin;
use Module::Find qw/useall/;

use lib $FindBin::Bin . '/../lib';
use Mittag::Config;
use Mittag::DB::Schema;
use Mittag::Importer;


my $config = Mittag::Config->new($FindBin::Bin . '/..');
my $path   = $FindBin::Bin . '/../data';


my $schema   = Mittag::DB::Schema->connect_with_config($config);
my $importer = Mittag::Importer->new({
    config => $config,
    schema => $schema,
});

my @places = useall 'Mittag::Place';

if ($ARGV[0]) {
    @places = grep { /Mittag::Place::$ARGV[0]/ } @places;
}

foreach my $class (@places) {
    # load file
    my $file = $path . '/' . $class->file;
    my $data = read_file $file, binmode => ':utf8';
    $class->extract($data, $importer);
}
