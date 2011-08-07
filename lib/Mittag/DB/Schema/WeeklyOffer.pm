package Mittag::DB::Schema::WeeklyOffer;

use DBIx::Class::Candy -components => [qw/InflateColumn::DateTime +Mittag::DB::Component::Place/];


table 'weekly_offer';

column id        => {data_type => 'INTEGER', is_nullable => 0};
column place_id  => {data_type => 'INTEGER', is_nullable => 0};
column from_date => {data_type => 'DATE',    is_nullable => 0};
column to_date   => {data_type => 'DATE',    is_nullable => 0};
column name      => {data_type => 'VARCHAR', is_nullable => 0};
column price     => {data_type => 'DECIMAL', is_nullable => 0};

primary_key 'id';


1;
