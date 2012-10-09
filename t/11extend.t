use Test::More;
use MooX::Struct Point => [qw( +x +y )];

my $point = Point[];
my $old_id = $point->OBJECT_ID;

is($point->TYPE, 'Point');
is_deeply([$point->FIELDS], ['x', 'y']);
ok( $point->can('x'));
ok( $point->can('y'));
ok(!$point->can('z'));

$point->EXTEND(\"Point3D", '+z');

is($point->TYPE, 'Point3D');
is_deeply([$point->FIELDS], ['x', 'y', 'z']);
ok( $point->can('x'));
ok( $point->can('y'));
ok( $point->can('z'));

is($point->OBJECT_ID, $old_id, 'OBJECT_ID does not change during EXTEND');

my $new = $point->CLONE(z => 0)->EXTEND(\"Point4D", '+w');
is_deeply([$point->FIELDS], ['x', 'y', 'z']);
is_deeply([$new->FIELDS], ['x', 'y', 'z', 'w']);

isnt($new->OBJECT_ID, $old_id, 'OBJECT_ID does change during CLONE+EXTEND');

done_testing;
