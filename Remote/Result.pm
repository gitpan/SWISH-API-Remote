package SWISH::API::Remote::Result;
use SWISH::API::Remote::FunctionGenerator;
use fields qw( properties );
use strict;
use warnings;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    $self->{properties} = {};     # empty hash
    return $self;
}
sub New_From_Query_String {
	my ($qs, $resultsprops) = @_;
	my $self = new SWISH::API::Remote::Result;
	my @parts = split(/&/, $qs);
	for my $p (@parts) {
		my ($n, $v) = split(/=/, $p, 2);
		$resultsprops->[$n] = "Unknown$n" unless defined($resultsprops->[$n]);
		#warn "Property number $n ( $resultsprops->[$n] ) : value $v\n";
		$self->{properties}{ $resultsprops->[$n] } = URI::Escape::uri_unescape($v || "")
			if defined($n);
	}
	#print Data::Dumper::Dumper($self);
	return $self;
}

sub Property {
	my ($self, $prop) = @_;
	#print "Looking up property $prop\n";
	return exists($self->{properties}) ? $self->{properties}{$prop} : "";
}
sub Properties {
	my $self = shift;
	return keys( %{ $self->{properties} } );
}

1;


__END__

=head1 NAME

SWISH::API::Remote::Result - Represents a single 'hit' from swished

=head1 DESCRIPTION

Performs searches on a remote swished server using an interface similar to SWISH::API

=over 4

=item my @properties = $result->Properties();

returns a list of the properties fetched for the result.

=item my $value = $result->Property('swishtitle');

returns a the named property.

=back

=head1 SEE ALSO

L<SWISH::API::Remote::Results>, L<SWISH::API::Remote>, L<swish-e>

=head1 AUTHOR

Josh Rabinowitz, E<lt>joshr@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Josh Rabinowitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
