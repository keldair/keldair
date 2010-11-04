#!/usr/bin/env perl -wW

# Keldair.pm - Main module file for Keldair
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

package Keldair;

use strict;
use warnings;
use diagnostics;
use IO::Socket;
use Exporter 'import';
use Config::JSON;
use Module::Load;
use Method::Signatures;
use constant {
    VERSIONSTRING => '2.0.0',
    VERSION       => 2,
    SUBVERSION    => 0,
    REVISION      => 0,
    RELEASESTAGE  => '',
    RELEASE       => ''
};

# Note for future maintainers:
# VERSIONSTRING = Keldair::VERSION.'.'.Keldair::SUBVERSION.'.'.Keldair::REVISION.'-'.Keldair::RELEASESTAGE.Keldair::RELEASE;

@Keldair::EXPORT_OK =
  qw(modlist modload act ban config ctcp kick kill mode msg notice oper snd);

our ( @modules, $sock, $SETTINGS );

# Remember to allow anything you want to call in modules.

method new ($config) {
    $SETTINGS = Config::JSON->new($config) or die("Cannot open config file!\n");
    my $modref = $SETTINGS->get("modules");
    my @tmp    = @$modref;
    foreach my $mod (@tmp) {
        modload($mod);
    }
    push( @modules, 'main' );
    $self->_connect( config('server/host'), config('server/port') );
}

method _loop {
    my (
        $line,    $nickname,  $command,    $mtext, $hostmask,
        $channel, $firstword, @spacesplit, @words
    );
    while ( $line = <$sock> ) {

        undef $nickname;
        undef $command;
        undef $mtext;
        undef $hostmask;

        chomp($line);
        chomp($line);

        # Hey, let's print the line too!
        print( $line. "\r\n" ) if config('debug/verbose') == 1;

        $hostmask = substr( $line, index( $line, ":" ) );
        $mtext =
          substr( $line, index( $line, ":", index( $line, ":" ) + 1 ) + 1 );
        ( $hostmask, $command ) =
          split( " ", substr( $line, index( $line, ":" ) + 1 ) );
        ( $nickname, undef ) = split( "!", $hostmask );
        @spacesplit = split( " ", $line );
        $channel = $spacesplit[2];

        my $handler = 'handle_' . lc($command);

        foreach my $cmd (@modules) {
            eval { $cmd->$handler( $hostmask, $channel, $mtext, $line ); };
        }

        if ( $command eq 'PRIVMSG' ) {
            my $cmdchar = config('cmdchar');
            if ( $mtext =~ /^$cmdchar/ ) {
                my $text = substr( $mtext, length($cmdchar) );
                my @parv = split( ' ', $text );
                my $handler = 'command_' . lc( $parv[0] );
                my ( %user, $rubbish );
                ( $user{'nick'}, $rubbish ) = split( '!', $hostmask );
                ( $user{'ident'}, $user{'host'} ) = split( '@', $garbage );
                foreach my $cmd (@modules) {
                    eval { $cmd->$handler( @parv, $channel, %user, $mtext ); };
                }
            }
        }
        elsif ( $command eq '001' ) {
            foreach my $cmd (@modules) {
                eval { $cmd->on_connect; };
            }
        }

        if ( $line =~ /^PING :/ ) {
            snd( "PONG :" . substr( $line, index( $line, ":" ) + 1 ) );
        }
    }
    foreach my $cmd (@modules) {
        eval { $cmd->on_disconnect; };
    }
}

method _connect ($host, $port) {
    if ( config('server/ssl') =~ /^y.*/ ) {
        require IO::Socket::SSL;
        $sock = IO::Socket::SSL->new(
            Proto    => "tcp",
            PeerAddr => $host,
            PeerPort => $port,
        ) or die("Connection failed to $host: $!\n");
    }
    else {
        $sock = IO::Socket::INET->new(
            Proto    => "tcp",
            PeerAddr => $host,
            PeerPort => $port,
        ) or die("Connection failed to $host. \n");
    }
    Keldair::connect(
        config('keldair/user'),
        config('keldair/real'),
        config('keldair/nick')
    );
    $self->_loop;
}

method connect ($ident, $gecos, $nick) {
    my $pass = config('server/pass');
    $self->snd("PASS $pass") if defined($pass);
    $self->snd("USER $ident * * :$gecos");
    $self->snd("NICK $nick");
}

#---------------------------------------------
# Below here, only the API commands are shown.
#---------------------------------------------

func modload ($mod) {
    eval { load $mod; };
    eval { $mod->_modinit; };
    push( @modules, $mod );
}

func modreload ($mod) {
    modunload($mod);
    modload($mod);
}

func modunload ($mod) {
	no $mod;
	@modules = grep{!/^$mod$/}
}

func modlist {
    return @modules;
}

func config ($value) {
    my $setting = $SETTINGS->get($value);
    return $setting;
}

#------------------------
# IRC commands only here.
#------------------------

func snd ($text) {
	chomp($text);
	print("SEND: $text\r\n") if config('debug/verbose') == 1;
	send( $sock, $text . "\r\n", 0);
}

func msg ($target, $text) {
    snd( "PRIVMSG " . $target . " :" . $text );
}

func notice ($targetl $text) {
    snd( "NOTICE " . $target . " :" . $text );
}

func ctcp ($target, $text) {
    snd( "PRIVMSG " . $target . " :\001" . $text . "\001" );
}

func act ($target, $text) {
    snd( "PRIVMSG " . $target . " :\001ACTION " . $text . "\001" );
}

func oper ($name, $pass) {
    snd( 'OPER ' . $name . ' ' . $pass );
}

func kill ($target, $msg) {
    snd("KILL $target :$msg");
}

func ban ($channel, $host) {
    snd("MODE $channel +b $host");
}

func kick ($channel, $nick, $reason) {
    snd("KICK $channel $nick :$reason");
}

sub mode ($target, $modes) {
    snd("MODE $target $modes");
}

1;
