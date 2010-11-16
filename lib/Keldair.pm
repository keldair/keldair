#!/usr/bin/env perl -wW

# Keldair.pm - Main module file for Keldair
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

package Keldair;

use strict;
use warnings;
use diagnostics -verbose;
use Carp qw(cluck croak);
use IO::Socket;
use Exporter 'import';
use Module::Load;
use Config::JSON;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use constant {
    VERSIONSTRING => '2.0.0',
    VERSION       => 2,
    SUBVERSION    => 0,
    REVISION      => 0,
    RELEASESTAGE  => ' ',
    RELEASE       => ' '
};

# Note for future maintainers:
# VERSIONSTRING = Keldair::VERSION.'.'.Keldair::SUBVERSION.'.'.Keldair::REVISION.'-'.Keldair::RELEASESTAGE.Keldair::RELEASE;

@Keldair::EXPORT_OK =
  qw(modlist modload act ban config ctcp kick kill mode msg notice oper snd);

our ( @modules, $sock, $SETTINGS );

# Remember to allow anything you want to call in modules.

sub new {
    my $self = shift;
    my ($config) = @_;
    $SETTINGS = Config::JSON->new($config) or die("Cannot open config file!\n");
    my $modref = $SETTINGS->get("modules");
    my @tmp    = @$modref;
    foreach my $mod (@tmp) {
        Keldair::modload($mod);
    }
    push( @modules, 'main' );
    Keldair::_connect( config('server/host'), config('server/port') );
}

sub _loop {
    my (
        $line,     $nickname, $command,   $mtext,
        $hostmask, $channel,  $firstword, @spacesplit,
        @words,    $origin,   $target,    $params
    );
    while ( $line = <$sock> ) {

        $line =~ s/\r\n//x;

        # Hey, let's print the line too!
        print( '>> ' . $line . "\r\n" );

        if ( $line =~
            /^(?:\:([^\s]+)\s)?(\w+)\s(?:([^\s\:]+)\s)?(?:\:?(.*))?$/x )
        {
            $origin  = $1;
            $command = $2;
            $target  = $3;
            $params  = $4;
                #if ( $origin =~ /(.*)!(.*)\@(.*)/x ) {
                 #   $origin = {
                  #      'hostmask' => $origin,
                   #     'nick'     => $1,
                    #    'user'     => $2,
                     #   'host'     => $3
                    #};
               # }
        }
        else {
            ( $command, $params ) = split( ' ', $line );
        }

     #        $hostmask = substr( $line, index( $line, ":" ) );
     #        $mtext =
     #        substr( $line, index( $line, ":", index( $line, ":" ) + 1 ) + 1 );
     #        ( $hostmask, $command ) =
     #        split( " ", substr( $line, index( $line, ":" ) + 1 ) );
     #        ( $nickname, undef ) = split( "!", $hostmask );
     #        @spacesplit = split( " ", $line );
     #        $channel = $spacesplit[2];

        my $handler = 'handle_' . lc($command);

        foreach my $cmd (@modules) {
            eval { $cmd->$handler( $origin, $target, $params, $line ); };
        }

        if ( $command eq 'PRIVMSG' ) {
            my $cmdchar = config('cmdchar');
            if ( $mtext =~ /^$cmdchar/ix ) {
                my $text = substr( $params, length($cmdchar) );
                my @parv = split( ' ', $text );
                my $handler = 'command_' . lc( $parv[0] );
                foreach my $cmd (@modules) {
                    eval { $cmd->$handler( @parv, $target, $origin, $params ); };
                }
            }
        }
        elsif ( $command eq '001' ) {
            foreach my $cmd (@modules) {
                eval { $cmd->on_connect; };
            }
        }

        if ( $line =~ /^PING :/x ) {
            snd( "PONG :" . substr( $line, index( $line, ":" ) + 1 ) );
        }

    }
    foreach my $cmd (@modules) {
        eval { $cmd->on_disconnect; };
    }
    return 1;
}

sub _connect {
    my ( $host, $port ) = @_;
    if ( Keldair::config('server/ssl') =~ /^y.*/ix ) {
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
        Keldair::config('keldair/user'),
        Keldair::config('keldair/real'),
        Keldair::config('keldair/nick')
    );
    _loop
      or croak(
"Missing Keldair::_loop, report this to http://github.com/keldair/keldair!"
      ) and return 0;
}

sub connect {
    my ( $ident, $gecos, $nick ) = @_;
    my $pass = config('server/pass');

    foreach my $cmd (@modules) {
        eval { $cmd->on_preconnect; };
        print("$!\n") if $!;
    }
    snd("PASS $pass") if defined($pass);
    snd("USER $ident * * :$gecos");
    snd("NICK $nick");
    return 1;
}

#---------------------------------------------
# Below here, only the API commands are shown.
#---------------------------------------------

sub modload {
    my ($mod) = @_;
    #eval { load $mod; }      or cluck("Loading $mod failed\n") and return 0;
    eval { load $mod; }; print("Err: $!\n") if $!;
    eval { $mod->_modinit; }; print("Err: $!\n") if $1;
    #eval { $mod->_modinit; } or cluck("Missing _modinit!")      and return 0;
    push( @modules, $mod );
    return 1;
}

#sub modreload {
#my ($mod) = $_[0];
#modunload($mod);
#modload($mod);
#}

#sub modunload {
#my ($module) = $_[0];
#no $module;
#@modules = grep{!/^$module$/};
#}

sub modlist {
    return @modules;
}

sub config {
    my ($value) = @_;
    my $setting = $SETTINGS->get($value);
    return $setting;
}

#------------------------
# IRC commands only here.
#------------------------

sub snd {
    my ($text) = @_;
    chomp($text);
    print("<< $text\r\n") if config('debug/verbose') == 1;
    send( $sock, $text . "\r\n", 0 );
    return $text;
}

sub msg {
    my ( $target, $text ) = @_;
    snd( "PRIVMSG " . $target . " :" . $text );
    return 1;
}

sub notice {
    my ( $target, $text ) = @_;
    snd( "NOTICE " . $target . " :" . $text );
    return 1;
}

sub ctcp {
    my ( $target, $text ) = @_;
    snd( "PRIVMSG " . $target . " :\001" . $text . "\001" );
    return 1;
}

sub act {
    my ( $target, $text ) = @_;
    snd( "PRIVMSG " . $target . " :\001ACTION " . $text . "\001" );
    return 1;
}

sub oper {
    my ( $name, $pass ) = @_;
    snd("OPER $name $pass");
    return 1;
}

sub userkill {
    my ( $target, $msg ) = @_;
    snd("KILL $target :$msg");
    return 1;
}

sub ban {
    my ( $channel, $host ) = @_;
    snd("MODE $channel +b $host");
    return 1;
}

sub kick {
    my ( $channel, $target, $reason ) = @_;
    snd("KICK $channel $target :$reason");
    return 1;
}

sub mode {
    my ( $target, $modes ) = @_;
    snd("MODE $target $modes");
    return 1;
}

sub topic {
    my ( $channel, $topic ) = @_;
    snd("TOPIC $channel :$topic");
    return 1;
}

sub away {
    my $reason = @_;
    snd("AWAY :$reason");
    return 1;
}

sub back {
    snd("AWAY");
    return 1;
}

sub cjoin {
    my $channel = @_;
    snd("JOIN $channel");
    return 1;
}

1337*(22/7) <= 9001;
