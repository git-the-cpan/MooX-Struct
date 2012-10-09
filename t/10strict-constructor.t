use Test::More tests => 1;
use MooX::Struct Thingy => [qw/ $x /];

ok not eval { my $thingy = Thingy->new(y => 1) };
