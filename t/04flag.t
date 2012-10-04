use strict;
use Test::More tests => 1;
use MooX::Struct -rw,
	Agent        => [qw( name )],
	Person       => [ -isa => ['Agent'] ];

my $bob   = Person->new(name => 'Bob');

note sprintf("Agent class:         %s", Agent);
note sprintf("Person class:        %s", Person);

$bob->name('Robert');
is($bob->name, 'Robert');