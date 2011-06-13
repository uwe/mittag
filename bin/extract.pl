#!/usr/bin/perl

use strict;
use warnings;

use Encode       qw/decode/;
use File::Slurp  qw/read_file/;
use FindBin;
use Module::Find qw/useall/;

use lib $FindBin::Bin . '/../lib';
use Mittag::Importer;
use Mittag::Schema;


my $config = do $FindBin::Bin . '/../config.pl';
my $path   =    $FindBin::Bin . '/../data';


my $schema   = Mittag::Schema->connect_with_config($config);
my $importer = Mittag::Importer->new({schema => $schema});
my @places = useall 'Mittag::Place';
foreach my $class (@places) {
    # load file
    my $file = $path . '/' . $class->file;
    my $data = read_file $file, binmode => ':utf8';
    $class->extract($data, $importer);
}
