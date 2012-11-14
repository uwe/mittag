package Mittag::Place::Kartoffelstube;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place::Leopolds/;


sub id       { 15 }
sub url      { 'http://www.die-kartoffelstube.de/pages/mittagskarte' }
sub file     { 'kartoffelstube.html' }
sub name     { 'Kartoffelstube' }
sub type     { 'web' }
sub address  { 'Hamburger Stadtkrug
Colonnaden 45
20354 Hamburg' }
sub phone    { '040/3480257' }
sub email    { 'info@die-kartoffelstube.de' }
sub homepage { 'http://www.die-kartoffelstube.de/' }
sub geocode  { [53.55736, 9.98975] }

sub table_index { 0 }

1;
