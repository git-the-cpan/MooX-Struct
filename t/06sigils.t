=head1 PURPOSE

Check that the required (C<< ! >>) postfix sigil works, and that the
scalar ((C<< $ >>), array (C<< @ >>) and hash (C<< % >>) prefix sigils
work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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
