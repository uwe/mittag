package Mittag::Web;

use FindBin;
use Mojo::Base 'Mojolicious';

use Mittag::Config;
use Mittag::DB::Schema;


has schema => sub {
    my $config = Mittag::Config->new($FindBin::Bin . '/..');
    Mittag::DB::Schema->connect_with_config($config);
};


sub rs {
    return (shift)->schema->resultset('Mittag::DB::Schema::' . shift);
}

sub startup {
    my ($self) = @_;

    $self->helper(format_price => sub {
        my ($self, $price) = @_;
        $price = sprintf('%.2f', $price);
        $price =~ tr/./,/;
        return $price;
    });

    my $r = $self->routes;

    $r->route('/'         )->to('day#today');
    $r->route('/day'      )->to('day#today');
    $r->route('/day/:date')->to('day#date')->name('day');
    $r->route('/day/today')->to('day#date')->name('today');

    $r->route('/place/:id')->to('place#show');

    # compatibility with old mobile URLs
    $r->route('/day/:date/1')->to('day#date');
}


1;
