#!/usr/bin/perl

use strict;
use warnings;

use File::Slurp  qw/read_file/;
use FindBin;
use Getopt::Long;
use Module::Find qw/useall/;

use lib $FindBin::Bin . '/../lib';
use Mittag::Config;
use Mittag::DB::Schema;
use Mittag::Importer;


my $debug = 0;
GetOptions(
    'debug|d' => \$debug,
);

my $config   = Mittag::Config->new($FindBin::Bin . '/..');
my $schema   = Mittag::DB::Schema->connect_with_config($config);
my $importer = Mittag::Importer->new({
    config => $config,
    debug  => $debug,
    schema => $schema,
});

my @places = useall 'Mittag::Place';
if ($ARGV[0]) {
    @places = grep { /Mittag::Place::$ARGV[0]/ } @places;
}
foreach my $class (@places) {
    next unless $class->type eq 'web';

    print "$class\n" if $debug;

    # load file
    my $file = $config->{path_web} . $class->file;
    next unless -f $file;
    eval {
        my $data = read_file $file, binmode => ':utf8';
        $class->extract($data, $importer);
    };
    warn $@ if $@;
}
