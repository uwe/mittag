package Mittag::Downloader;

# download and convert utilities

use strict;
use warnings;

use base qw/Class::Accessor::Faster/;

use Encode      qw//;
use File::Slurp qw//;
use IPC::Run3   qw//;
use LWP::Simple qw//;


__PACKAGE__->mk_ro_accessors(qw/config path/);


sub get {
    my ($self, $url) = @_;

    return LWP::Simple::get($url);
}

sub get_store {
    my ($self, $url, $name) = @_;

    my $file = $self->path . '/' . $name;
    LWP::Simple::getstore($url, $file);
}

sub store {
    my ($self, $data, $name) = @_;

    my $file = $self->path . '/' . $name;
    File::Slurp::write_file $file, {binmode => ':utf8'}, $data;
}

sub html2txt {
    my ($self, $name) = @_;

    my $file = $self->path . '/' . $name;

    my $txt;
    IPC::Run3::run3 [qw/lynx --dump --nomargins --nolist --width=1000/, $file], undef, \$txt;

    return Encode::decode('utf8', $txt);
}

sub pdf2txt {
    my ($self, $name) = @_;

    my $file = $self->path . '/' . $name;

    my $txt;
    IPC::Run3::run3 [qw/pdftotext -raw/, $file, '-'], undef, \$txt;

    return Encode::decode('utf8', $txt);
}


1;
