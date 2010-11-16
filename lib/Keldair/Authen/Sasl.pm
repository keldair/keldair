package Keldair::Authen::Sasl;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
#use Keldair qw(snd config);

sub _modinit {
    print(__PACKAGE__." loaded\n");
}

sub on_preconnect {
    snd("CAP LS");
}

sub handle_cap {
    my ( $self, $hostmask, $channel, $mtext, $line ) = @_;
    my ( $subcmd, $caps, $tosend );
    if ( $line =~ / LS / ) {
        if ($line =~ /multi-prefix/i) { $tosend .= ' multi-prefix'; }
        if ($line =~ /sasl/i)  { { $tosend .= ' sasl'; } }
       # $tosend .= ' multi-prefix' if ( $line =~ /multi-prefix/i );
        #$tosend .= ' sasl'
         # if $line =~ /sasl/i && defined( config('auth/user') );
        #$tosend = s/^ //;
        if ( $tosend eq '' ) {
            snd("CAP END");
        }
        else {
            snd("CAP REQ :$tosend");
        }
    }
    elsif ( $line =~ / ACK / ) {
        if ( $mtext =~ /sasl/i ) {
            snd("AUTHENTICATE PLAIN");
        }
        else {
            snd("CAP END");
        }
    }
    elsif ( $line =~ / NAK / ) {
        snd("CAP END");
    }
}

sub handle_authenticate {
    my $u   = config('auth/user');
    my $p   = config('auth/pass');
    my $out = join( "\0", $u, $u, $p );
    $out = encode_base64( $out, "" );

    if ( length $out == 0 ) {
        snd("AUTHENTICATE +");
        return;
    }
    else {
        while ( length $out >= 400 ) {
            my $subout = substr( $out, 0, 400, '' );
            snd("AUTHENTICATE $subout");
        }
        if ( length $out ) {
            snd("AUTHENTICATE $out");
        }
        else {
            snd("AUTHENTICATE +");
        }
    }
}

sub handle_903 {
    snd("CAP END");
}

sub handle_904 {
    snd("CAP END");
}

1;
