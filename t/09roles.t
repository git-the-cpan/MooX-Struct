use Test::More;

BEGIN {
	package Local::Role1;
	use Moo::Role;
	has attr1 => (is => 'ro');
}

BEGIN {
	package Local::Role2;
	use Moo::Role;
	has attr2 => (is => 'ro');
}

use MooX::Struct
	Thingy => [
		-with  => [qw( Local::Role2 Local::Role1 )],
		qw/ $attr3 $attr4 /,
	],
;

is_deeply(
	[ Thingy->FIELDS ],
	[ qw/ attr2 attr1 attr3 attr4 / ],
);

my $thingy = Thingy[qw/ 2 1 3 4 /];
is($thingy->attr1, 1);
is($thingy->attr2, 2);
is($thingy->attr3, 3);
is($thingy->attr4, 4);

done_testing;
