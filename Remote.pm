package SWISH::API::Remote;
use SWISH::API::Remote::Results;
use SWISH::API::Remote::Result;
use SWISH::API::Remote::FunctionGenerator;

use strict;
use warnings;
#use Data::Dumper;

use fields qw(uri index debug);
use URI::Escape; # for uri_(un)escape
use LWP::UserAgent;

our $VERSION = '0.07'; 
use constant DEFAULT_PROPERTIES => "swishrank,swishdocpath,swishtitle,swishdocsize";

sub new {
	my ($proto, $uri, $index, $opts_hash) = @_;
	$opts_hash = {} unless defined($opts_hash);
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);
	$self->{uri} = $uri;
	$self->{index} = $index || "DEFAULT";
	$self->{debug} = $opts_hash->{DEBUG} || 0;
	return $self;
} 
sub Execute {
	my $self = shift;
	my $query = shift || "";
	my $searchopts = shift || {};
	my $uri = $self->{uri} . "?f=" . $self->{index} . "&w=" . uri_escape($query);
	if (exists($searchopts->{PROPERTIES}) && $searchopts->{PROPERTIES}) {
		$uri .= "&p=" . $searchopts->{PROPERTIES};
	} else {
		$uri .= "&p=" . DEFAULT_PROPERTIES;
	}
	if (exists($searchopts->{BEGIN})) {
		$uri .= "&b=" . $searchopts->{BEGIN};
	}
	if (exists($searchopts->{MAX})) {
		$uri .= "&m=" . $searchopts->{MAX};
	}
	print "Fetching $uri\n" if ($self->{debug});

	my $ua = LWP::UserAgent->new;
	$ua->timeout(2);
	#$ua->env_proxy; 
	my $response = $ua->get( $uri );
	my $content = "";
	if ($response->is_success) {
		$content = $response->content;
	} else {
		$content = "e: Couldn't connect: " . $response->status_line . "\n";
		#print "$content";
	} 
	return $self->_ParseContent($content); 
}

sub _ParseContent { 	
# intended to be private. Parses the returned content into members
	my ($self, $content) = @_;
	#warn "Got content $content\n\n";
	my @results = ();
	my @resultprops = ();
	my $results = SWISH::API::Remote::Results->new();
	#my @lines = split(/\n/, $content);
	#for my $line (@lines) {
	for my $line (split(/\n/, $content)) {
		next unless $line;
		if ($line =~ s/^k:\s*//) {	  # the 'key'
			@resultprops = map { (split(/=/, $_))[1] } (split (/&/, $line));
			#print Data::Dumper::Dumper(\@resultprops);
		}
		if ($line =~ s/^r:\s*//) {
			my $result = SWISH::API::Remote::Result::New_From_Query_String( $line, \@resultprops );
			$results->AddResult($result);
		} 
		if ($line =~ s/^e:\s*//) {
			$results->AddError($line);
			print "Added error: $line\n" if $self->{debug};
		} 
		if ($line =~ s/^m:\s*.*hits=(\d+)//) {	
			# in the future we'll probably parse more from this Meta line
			$results->Hits($1);
		}
	} 
	return ($results);
} 
SWISH::API::Remote::FunctionGenerator::makeaccessors(
	__PACKAGE__, qw ( uri index )
);


1;
__END__

=head1 NAME

SWISH::API::Remote - Perl module to perform searches on a swished daemon server

=head1 SYNOPSIS

    use SWISH::API::Remote;
    my $sw = SWISH::API::Remote->new( 'http://yourserverLLD.com/swished');
    my $w = "foo OR bar";
    my $results = $sw->Execute( $w );
    printf("Fetched %d of %d hits for search on '%s'\n",
        $results->Fetched(), $results->Hits(), $w);
    while ( my $r = $results->NextResult() ) {
        print join(" ", map { $r->Property($_) } ($r->Properties()) ) . "\n";
    }
    if ($results->Error()) {
        die $results->ErrorString();
    }

=head1 DESCRIPTION

Performs searches on a remote swished server using an interface similar to SWISH::API

=over 4

=item my $remote = SWISH::API::Remote->new( "http://yourserv.com/swished", "INDEX", \%remote_options);

Creates a SWISH::API::Remote object. $options{DEBUG} is the only recognized key of %options
so far.

=item my $results = $remote->Execute( $search, \%search_options);

Performs a search using SWISH::API::Remote and returns a SWISH::API::Results
object. Recognized search_options are:
	MAX:        the maximum number of hits to fetch (default 10)
	BEGIN:      which hit to start at               (default  0)
	PROPERTIES: which properties to fetch           (default  0)

=back

=head1 SEE ALSO

L<SWISH::API::Remote::Results>, L<SWISH::API::Remote::Result>

=head1 AUTHOR

Josh Rabinowitz, E<lt>joshr@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Josh Rabinowitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
