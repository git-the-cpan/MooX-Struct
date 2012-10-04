use Test::More skip_all => 'undocumented feature; not fully working';
use MooX::Struct Structure => [qw( $value %dict @list )];

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

done_testing();