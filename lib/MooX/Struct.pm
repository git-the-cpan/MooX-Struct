package MooX::Struct;

use 5.008;
use strict;
use warnings;
use utf8;

BEGIN {
	$MooX::Struct::AUTHORITY = 'cpan:TOBYINK';
	$MooX::Struct::VERSION   = '0.004';
}

use Moo         1.000000;
use Object::ID  0         qw( object_id );

BEGIN {
	package MooX::Struct::Processor;
	
	use Moo                  1.000000;
	use Carp                 0         qw( confess      );
	use Data::OptList        0         qw(              );
	use Sub::Install         0         qw( install_sub  );
	use Scalar::Does         0         qw( does blessed );
	use namespace::clean               qw(              );
	use B::Hooks::EndOfScope           qw( on_scope_end );

	has flags => (
		is       => 'ro',
		isa      => sub { die "flags must be HASH" unless does $_[0], 'HASH' },
		default  => sub { +{} },
	);
	
	has class_map => (
		is       => 'ro',
		isa      => sub { die "class_map must be HASH" unless does $_[0], 'HASH' },
		default  => sub { +{} },
	);
	
	has base => (
		is       => 'ro',
		default  => sub { 'MooX::Struct' },
	);
	
	has 'caller' => (
		is       => 'ro',
		required => 1,
	);
	
	has trace => (
		is       => 'lazy',
	);
	
	sub _build_trace
	{
		$ENV{PERL_MOOX_STRUCT_TRACE}
		or shift->flags->{trace};
	}

	has trace_handle => (
		is       => 'lazy',
	);
	
	sub _build_trace_handle
	{
		require IO::Handle;
		\*STDERR;
	}

	my $counter = 0;
	sub create_class
	{
		my $self  = shift;
		my $klass = sprintf('%s::__ANON__::%04d', $self->base, ++$counter);
		Moo->_set_superclasses($klass, $self->base);
		Moo->_maybe_reset_handlemoose($klass);
		if ($self->trace)
		{
			$self->trace_handle->printf(
				"package %s;\nuse Moo;\n",
				$klass,
			);
		}
		return $klass;
	}
	
	sub process_meta
	{
		my ($self, $klass, $name, $val) = @_;
		
		if ($name eq '-extends' or $name eq '-isa')
		{
			my @parents = map {
				exists $self->class_map->{$_}
					? $self->class_map->{$_}->()
					: $_
			} @$val;
			Moo->_set_superclasses($klass, @parents);
			Moo->_maybe_reset_handlemoose($klass);
			
			if ($self->trace)
			{
				$self->trace_handle->printf(
					"extends qw(%s)\n",
					join(q[ ] => @parents),
				);
			}
		}
		else
		{
			confess("option '$name' unknown");
		}
		
		return;
	}
	
	sub process_method
	{
		my ($self, $klass, $name, $coderef) = @_;
		install_sub {
			into   => $klass,
			as     => $name,
			code   => $coderef,
		};
		if ($self->trace)
		{
			$self->trace_handle->printf(
				"sub %s { ... }\n",
				$name,
			);
			if ($self->flags->{deparse})
			{
				require B::Deparse;
				my $code = B::Deparse->new(qw(-q -si8T))->coderef2text($coderef);
				$code =~ s/^/# /mig;
				$self->trace_handle->printf("$code\n");
			}
		}
		return;
	}
	
	sub process_spec
	{
		my ($self, $klass, $name, $val) = @_;
		
		my %spec = (
			is => ($self->flags->{rw} ? 'rw' : 'ro'),
			( does($val, 'ARRAY')
				? @$val
				: ( does($val,'HASH') ? %$val : () )
			),
		);
		
		if ($name =~ /^(.+)\!$/)
		{
			$name = $1;
			$spec{required} = 1;
		}
		
		if ($name =~ /^\@(.+)/)
		{
			$name = $1;
			$spec{isa} ||= sub {
				die "wrong type for '$name' (not arrayref)"
					unless does($_[0], 'ARRAY');
			};
		}
		elsif ($name =~ /^\%(.+)/)
		{
			$name = $1;
			$spec{isa} ||= sub {
				die "wrong type for '$name' (not hashref)"
					unless does($_[0], 'HASH');
			};
		}
		elsif ($name =~ /^\$(.+)/)
		{
			$name = $1;
			$spec{isa} ||= sub {
				my $ref = ref($_[0]);
				die "wrong type for '$name' (should not be arrayref or hashref)"
					if $ref eq 'ARRAY' || $ref eq 'HASH';
			};
		}
		
		return ($name, \%spec);
	}
	
	sub process_attribute
	{
		my ($self, $klass, $name, $val) = @_;
		my $spec;
		($name, $spec) = $self->process_spec($klass, $name, $val);
		
		if ($self->trace)
		{
			require Data::Dumper;
			my $spec_str = Data::Dumper->new([$spec])->Terse(1)->Indent(0)->Dump;
			$spec_str =~ s/(^\{)|(\}$)//g;
			$self->trace_handle->printf(
				"has %s => (%s);\n",
				$name,
				$spec_str,
			);
			if ($self->flags->{deparse} and $spec->{isa})
			{
				require B::Deparse;
				my $code = B::Deparse->new(qw(-q -si8T))->coderef2text($spec->{isa});
				$code =~ s/^/# /mig;
				$self->trace_handle->printf("$code\n");
			}
		}

		Moo
			->_constructor_maker_for($klass)
			->register_attribute_specs($name, $spec);
			
		Moo
			->_accessor_maker_for($klass)
			->generate_method($klass, $name, $spec);
			
		Moo
			->_maybe_reset_handlemoose($klass);

		return;
	}
	
	sub process_argument
	{
		my $self = shift;
		my ($klass, $name, $val) = @_;
		
		confess("attribute '$name' seems to private")
			if $name =~ /^___/; # these are reserved for now!
		
		return $self->process_meta(@_)      if $name =~ /^-/;
		return $self->process_method(@_)    if does($val, 'CODE');
		return $self->process_attribute(@_);
	}
	
	sub make_sub
	{
		my ($self, $subname, $proto) = @_;
		return sub ()
		{
			1 if $] < 5.014; # bizarre, but necessary!
			if (ref $proto)  # inflate!
			{
				my $klass = $self->create_class;
				$self->process_argument($klass, @$_)
					for @{ Data::OptList::mkopt($proto) };
				$proto = $klass;
			}
			return $proto;
		}
	}
	
	sub process
	{
		my $self = shift;
		
		while (@_ and $_[0] =~ /^-(.+)$/) {
			$self->flags->{ lc($1) } = !!shift;
		}
		
		foreach my $arg (@{ Data::OptList::mkopt(\@_) })
		{
			my ($subname, $details) = @$arg;
			$details = [] unless defined $details;
			
			$self->class_map->{ $subname } = $self->make_sub($subname, $details);
			install_sub {
				into   => $self->caller,
				as     => $subname,
				code   => $self->class_map->{ $subname },
			};
		}
		on_scope_end {
			namespace::clean->clean_subroutines(
				$self->caller,
				keys %{ $self->class_map },
			);
		};
	}
};

sub import
{
	my $caller = caller;
	my $class  = shift;
	"$class\::Processor"->new(caller => scalar caller)->process(@_);
}

no Moo;
1;

__END__

=head1 NAME

MooX::Struct - make simple lightweight record-like structures that make sounds like cows

=head1 SYNOPSIS

 use MooX::Struct
    Point   => [ 'x', 'y' ],
    Point3D => [ -extends => ['Point'], 'z' ],
 ;
 
 my $origin = Point3D->new( x => 0, y => 0, z => 0 );

=head1 DESCRIPTION

MooX::Struct allows you to create cheap struct-like classes for your data
using L<Moo>.

While similar in spirit to L<MooseX::Struct> and L<Class::Struct>, 
MooX::Struct has a somewhat different usage pattern. Rather than providing
you with a C<struct> keyword which can be used to define structs, you
define all the structs as part of the C<use> statement. This means they
happen at compile time.

A struct is just an "anonymous" Moo class. MooX::Struct creates this class
for you, and installs a lexical alias for it in your namespace. Thus your
module can create a "Point3D" struct, and some other module can too, and
they won't interfere with each other. All struct classes inherit from
MooX::Struct; and MooX::Struct provides a useful method: C<object_id> (see
L<Object::ID>).

Arguments for MooX::Struct are key-value pairs, where keys are the struct
names, and values are arrayrefs.

 use MooX::Struct
    Person   => [qw/ name address /],
    Company  => [qw/ name address registration_number /];

The elements in the array are the attributes for the struct (which will be
created as read-only attributes), however certain array elements are treated
specially.

=over

=item *

As per the example in the L</SYNOPSIS>, C<< -extends >> introduces a list of
parent classes for the struct. If not specified, then classes inherit from
MooX::Struct itself.

Structs can inherit from other structs, or from normal classes. If inheriting
from another struct, then you I<must> define both in the same C<use> statement.

 # Not like this.
 use MooX::Struct Point   => [ 'x', 'y' ];
 use MooX::Struct Point3D => [ -extends => ['Point'], 'z' ];
 
 # Like this.
 use MooX::Struct
    Point   => [ 'x', 'y' ],
    Point3D => [ -extends => ['Point'], 'z' ],
 ;

=item *

If an attribute name is followed by a coderef, this is installed as a
method instead.

 use MooX::Struct
    Person => [
       qw( name age sex ),
       greet => sub {
          my $self = shift;
          CORE::say "Hello ", $self->name;
       },
    ];

But if you're defining methods for your structs, then you've possibly missed
the point of them.

=item *

If an attribute name is followed by an arrayref, these are used to set the
options for the attribute. For example:

 use MooX::Struct
    Person  => [ name => [ is => 'ro', required => 1 ] ];

=item *

Attribute names may be "decorated" with prefix and postfix "sigils". The prefix
sigils of C<< @ >> and C<< % >> specify that the attribute isa arrayref or
hashref respectively. (Blessed arrayrefs and hashrefs are accepted; as are
objects which overload C<< @{} >> and C<< %{} >>.) The prefix sigil C<< $ >>
specifies that the attribute value must not be an unblessed arrayref or hashref.
The postfix sigil C<< ! >> specifies that the attribute is required.

 use MooX::Struct
    Person  => [qw( $name! @children )];

 Person->new();         # dies, name is required
 Person->new(           # dies, children should be arrayref
    name     => 'Bob',
    children => 2,
 );

=back

Prior to the key-value list, some additional flags can be given. These begin
with hyphens. The flag C<< -rw >> indicates that attributes should be
read-write rather than read-only.

 use MooX::Struct -rw,
    Person => [
       qw( name age sex ),
       greet => sub {
          my $self = shift;
          CORE::say "Hello ", $self->name;
       },
    ];

Flags C<< -trace >> and C<< -deparse >> may be of use debugging.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Struct>.

=head1 SEE ALSO

L<Moo>, L<MooseX::Struct>, L<Class::Struct>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

