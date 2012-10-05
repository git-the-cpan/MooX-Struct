use Test::More;
use Scalar::Does;
use MooX::Struct
	Structure => [
		qw( $value %dict @list ),
		'%list2' => [ isa => sub { die unless does $_[0], 'ARRAY' } ],
	],
	OtherStructure => [qw( id! ego )],
;

ok eval {
	Structure->new( value => Structure->new )
};

ok eval {
	Structure->new( value => 42 )
};

ok eval {
	Structure->new( list => [] )
};

ok eval {
	Structure->new( dict => +{} )
};

ok eval {
	Structure->new( list2 => [] );
};

ok !eval {
	Structure->new( value => [] )
};

ok !eval {
	Structure->new( value => +{} )
};

ok !eval {
	Structure->new( list => 42 )
};

ok !eval {
	Structure->new( dict => 42 )
};

ok !eval {
	Structure->new( list2 => +{} );
};

ok eval {
	OtherStructure->new(id => undef);
};

ok !eval {
	OtherStructure->new(ego => undef);
};

done_testing();
