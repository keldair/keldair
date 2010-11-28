package Keldair::Core::Connect;
use strict;
use warnings;
use Carp qw(croak carp cluck confess);
use Keldair;

our ( $sock, %connecthash );

sub init {
    %connecthash = ( 
        'Proto'    => "tcp",
        'PeerAddr' => Keldair::config('server/host'),
        'PeerPort' => Keldair::config('server/port'),
        'Timeout'  => 30
    );

    if ( Keldair::config('server/ssl') =~ /^(y.*|on|1|t.*)$/i ) {
        eval { require IO::Socket::SSL; } or croak("Missing IO::Socket::SSL");

        if ( Keldair::config( 'ssl/certfp' =~ /^(y.*|on|1|t.*)$/ ) ) {
            $connecthash{'SSL_cert_file'} = Keldair::config('ssl/certfp/filename');
            if ( Keldair::config('ssl/certfp/passwd') ) {
                $connecthash{'SSL_passwd_cb'} =
                  sub { return Keldair::config('ssl/certfp/passwd'); }
            }
        }
        $sock = IO::Socket::SSL->new(%connecthash)
          or
          croak( "Connection failed to " . Keldair::config('server/host') . ": $!\n" );
    }

    else {
        $sock = IO::Socket::INET->new(%connecthash)
          or
          croak( "Connection failed to " . Keldair::config('server/host') . ": $!\n" );
    }

    return $sock;

}

1;
