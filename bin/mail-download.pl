#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use FindBin;
use File::Slurp;
use Mail::POP3Client;

use lib $FindBin::Bin . '/../lib';
use Mittag::Config;


my $config = Mittag::Config->new($FindBin::Bin . '/..');

# mail not configured
exit unless $config->{mail_user};


# unique file names
my $date = DateTime->now->strftime('%y%m%d-%H%M');

my $pop = Mail::POP3Client->new(
    USER     => $config->{mail_user},
    PASSWORD => $config->{mail_pass},
    HOST     => $config->{mail_host},
    USESSL   => $config->{mail_ssl},
);

my $count = $pop->Count;

if ($count > 0) {
    foreach my $msg (1 .. $count) {
        my $mail = $pop->Retrieve($msg);
        my $file = sprintf(
            '%s%s-%d.txt',
            $config->{path_mail},
            $date,
            $msg,
        );
        write_file($file, $mail);
    }
}
$pop->Close;
