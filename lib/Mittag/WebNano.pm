package Mittag::WebNano;

use Moose;

extends 'WebNano';

use FindBin;
use Template;

use Mittag::Schema;


has config => (is => 'ro', isa => 'HashRef', required => 1);
has schema => (is => 'ro', lazy => 1, builder => '_build_schema');
has tt     => (is => 'ro', lazy => 1, builder => '_build_tt');


sub _build_schema {
    my ($self) = @_;

    return Mittag::Schema->connect_with_config($self->config);
}

sub _build_tt {
    my ($self) = @_;

    return Template->new({
        INCLUDE_PATH => $FindBin::Bin . '/tmpl',
        POST_CHOMP   => 1,
    });
}


sub rs {
    my ($self, $model) = @_;

    return $self->schema->resultset('Mittag::Schema::' . $model);
}

sub render {
    my ($self, $tmpl, $vars) = @_;

    my $out = '';
    $self->tt->process($tmpl, $vars, \$out) or die $self->tt->error;

    return $out;
}


1;
