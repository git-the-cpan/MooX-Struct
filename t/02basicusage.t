use strict;
use Test::More tests => 12;
use MooX::Struct
	Organisation => [qw/ name employees /, company_number => [is => 'rw']],
	Person       => [qw/ name /];

my $alice = Person->new(name => 'Alice');
my $bob   = Person->new(name => 'Bob');
my $acme  = Organisation->new(name => 'ACME', employees => [$alice, $bob]);

note sprintf("Person class:        %s", Person);
note sprintf("Organisation class:  %s", Organisation);

is(
	ref($alice),
	ref($bob),
	'Alice and Bob are in the same class',
);

isnt(
	ref($alice),
	ref($acme),
	'Alice and ACME are not in the same class',
);

isa_ok($_, 'MooX::Struct', '$'.lc($_->name)) for ($alice, $bob, $acme);

is($alice->name, 'Alice', '$alice is called Alice');
is($bob->name, 'Bob', '$bob is called Bob');
is($acme->name, 'ACME', '$acme is called ACME');

ok !eval {
	$acme->name('Acme Inc'); 1
}, 'accessors are read-only by default';

$acme->company_number(12345);
is($acme->company_number, 12345, 'accessors can be made read-write');

can_ok $alice => 'object_id';
isnt($alice->object_id, $bob->object_id, 'object_id is unique identifier');