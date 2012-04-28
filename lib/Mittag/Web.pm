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
    return (shift)->schema->resultset('Mittag::DB::Schema::' . shift);
}

sub startup {
    my ($self) = @_;

    $self->plugin('tt_renderer');

    my $r = $self->routes;

    $r->route('/'         )->to('day#today');
    $r->route('/day'      )->to('day#today');
    $r->route('/day/:date')->to('day#date')->name('day');
    $r->route('/day/today')->to('day#date')->name('today');

    # compatibility with old mobile URLs
    $r->route('/day/:date/1')->to('day#date');
}


1;
