package Mittag::Web;

use Mojo::Base 'Mojolicious';

use Mittag::DB::Schema;


has schema => sub {
    my $config = {
                  db_name => 'mittag',
                  db_user => 'root',
                  db_pass => 'root',
                 };
    Mittag::DB::Schema->connect_with_config($config);
};


sub rs {
    my ($self, $model) = @_;

    return $self->schema->resultset('Mittag::DB::Schema::' . $model);
}

sub startup {
    my ($self) = @_;

    $self->plugin('tt_renderer');

    my $r = $self->routes;

    $r->route('/'         )->to('day#date');
    $r->route('/day'      )->to('day#date');
    $r->route('/day/:date')->to('day#date');
}


1;
