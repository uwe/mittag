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


sub days {
    return (
        ['Montag',     0, 0, 2],
        ['Dienstag',   2, 0, 2],
        ['Mittwoch',   0, 3, 6],
        ['Donnerstag', 2, 3, 6],
        ['Freitag',    4, 1, 4],
    );
}

sub single_column { 1 }


1;
