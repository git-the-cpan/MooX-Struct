use Test::More tests => 1;
BEGIN { use_ok('MooX::Struct') };

diag '';
diag sprintf("%-12s %s", q(Perl), $]);
diag sprintf("%-12s %s", $_, $_->VERSION)
	for qw( MooX::Struct Moo );
