=head1 PURPOSE

Check square-bracket-style constructor.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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