use Test::More;
use MooX::Struct
	Point   => [ qw( +x +y ) ],
	Point3D => [ -extends => [qw(Point)], qw( +z ) ],
;

my $point1 = Point[3, 4];
my $point2 = Point3D[3, 4, 5];
my $point3 = Point3D[3, 4];

is("$point1", "3 4");
is("$point2", "3 4 5");
is("$point3", "3 4 0");

done_testing();