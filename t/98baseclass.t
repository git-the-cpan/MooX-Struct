=head1 PURPOSE

Tests that a MooX::Struct::Processor, configured with a base class
that has some attributes, will generate structs that are aware of
those attributes (shows them in C<FIELDS>).

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use MooX::Struct Foo => ['$foo'];

BEGIN {
	"MooX::Struct::Processor"
		-> new(
			base  => Foo,
			flags => { retain => 1 },
		)
		-> process(
			main => (
				Bar => ['$bar'],
				Baz => ['$baz', -class => \'Baz'],
			),
		)
	;
};

is_deeply(
	[ Foo->FIELDS ],
	[ qw( foo ) ],
);

isa_ok(Bar, Foo);

is_deeply(
	[ Bar->FIELDS ],
	[ qw( foo bar ) ],
);

isa_ok(Baz, Foo);

is_deeply(
	[ Baz->FIELDS ],
	[ qw( foo baz ) ],
);

my $bar = Bar[1, 2];

is($bar->foo, 1);
is($bar->bar, 2);

done_testing;

