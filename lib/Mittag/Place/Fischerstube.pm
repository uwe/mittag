package Mittag::Place::Fischerstube;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place::Leopolds/;


sub id       { 18 }
sub url      { 'http://www.hamburger-fischerstube.de/pages/mittagskarte' }
sub file     { 'fischerstube.html' }
sub name     { 'Fischerstube' }
sub type     { 'web' }
sub address  { 'Hamburger Fischerstube
Colonnaden 49
20354 Hamburg' }
sub phone    { '040/35716380' }
sub email    { 'info@hamburger-fischerstube.de' }
sub homepage { 'http://www.hamburger-fischerstube.de/' }
sub geocode  { [53.55757, 9.98978] }

sub table_index { 0 }

1;
