use Test::More;

use MooX::Struct::Util qw/ lazy_default /;
use MooX::Struct Point => [ '+x', '+y' ];
use MooX::Struct Line  => [ '$start' => lazy_default { Point[] }, '$end' ];

my $line = Line->new( end => Point[ 2, 3 ] );
is("$line", "0 0 2 3");

done_testing();