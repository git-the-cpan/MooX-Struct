use Test::More tests => 1;
use MooX::Struct
	Person => [
		qw( name age sex ),
		uc_name => sub {
			my $self = shift;
			return uc $self->name;
		},
	];

is(Person->new(name => 'Bob')->uc_name, 'BOB');
