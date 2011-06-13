package Mittag::Schema::Place;

use namespace::autoclean;
use DBIx::Class::Candy;


table 'place';

column id   => {data_type => 'INTEGER', is_nullable => 0};
column name => {data_type => 'VARCHAR', is_nullable => 0};

primary_key 'id';

unique_constraint [qw/name/];


1;
