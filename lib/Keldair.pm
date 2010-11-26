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
use Sys::Hostname;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair::Core::Parser qw(parse_irc);
use constant {
    VERSIONSTRING => '2.2.1',
    VERSION       => 2,
    SUBVERSION    => 0,
    REVISION      => 0,
    RELEASESTAGE  => ' ',
    RELEASE       => ' '
};

# Note for future maintainers:
# VERSIONSTRING = Keldair::VERSION.'.'.Keldair::SUBVERSION.'.'.Keldair::REVISION.'-'.Keldair::RELEASESTAGE.Keldair::RELEASE;

@Keldair::EXPORT_OK =
  qw(act away back ban cjoin config connect ctcp kick mode modlist modload msg notice oper snd topic userkill);

our ( @modules, $sock, $SETTINGS );

# Remember to allow anything you want to call in modules.

sub new {
    my $self = shift;
    my ($config) = $_[0];
    $SETTINGS = Config::JSON->new($config)
      or die("Cannot open config file!\n");
    my $modref = $SETTINGS->get("modules");
    my @tmp    = @$modref;
    foreach my $mod (@tmp) {
        Keldair::modload($mod);
    }
    push( @modules, 'main' );
    foreach my $mod (@modules) {
        eval { $mod->on_startup; };
    }
    _connect( config('server/host'), config('server/port') ) or
        croak("Error connecting to server: $!\n");
    return 1;
}

sub _loop {
    my (
        $line,

    );
    while ( $line = <$sock> ) {

        $line =~ s/\r\n//x;

        # Hey, let's print the line too!
        print( '>> ' . $line . "\r\n" );

        my $event = parse_irc($line);

        my $handler = 'handle_' . lc( $event->{command} );

        foreach my $cmd (@modules) {
            eval {
                $cmd->$handler(
                    $event->{origin}, $event->{target},
                    $event->{params}, $line
                );
            };
        }

        if ( $event->{command} eq '001' ) {
            foreach my $cmd (@modules) {
                eval { $cmd->on_connect; };
            }
        }

        elsif ( $event->{command} eq 'PING') {
            #snd( "PONG :" . substr( $line, index( $line, ":" ) + 1 ) );
            snd( "PONG :$event->{params}" );
        }

    }
    foreach my $cmd (@modules) {
        eval { $cmd->on_disconnect; };
    }
    return 1;
}

sub _connect {
    #SSL option connection nonsense stolen, mostly, from miniCruzer's ZeroBot
    my ( $host, $port ) = @_;
    if ( Keldair::config('server/ssl') =~ /^y.*/ix ) {
        require IO::Socket::SSL;
        $sock = IO::Socket::SSL->new(
            Proto    => "tcp",
            PeerAddr => $host,
            PeerPort => $port,
            Timeout  => 30
        ) or croak("Connection failed to $host: $!\n");
    }
    else {
        $sock = IO::Socket::INET->new(
            Proto    => "tcp",
            PeerAddr => $host,
            PeerPort => $port,
            Timeout  => 30
        ) or croak("Connection failed to $host. \n");
    }
    Keldair::connect(
        config('keldair/user'),
        config('keldair/real'),
        config('keldair/nick')
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
    }
    snd("PASS $pass") if defined($pass);
    snd(    "USER $ident "
          . hostname . " "
          . config('server/host')
          . " :$gecos" );
    snd("NICK $nick");
    return 1;
}

#---------------------------------------------
# Below here, only the API commands are shown.
#---------------------------------------------

sub modload {
    my ($mod) = @_;
    eval { load $mod; };
    print("$mod failed: $!\n") if $!;
    eval { $mod->modinit; };
    print( "$mod" . "::modinit failed: $!\n" ) if $!;

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
    snd("PRIVMSG $target :$text");
    return 1;
}

sub notice {
    my ( $target, $text ) = @_;
    snd("NOTICE $target :$text");
    return 1;
}

sub ctcp {
    my ( $target, $text ) = @_;
    snd( "PRIVMSG $target :\001$text\001");
    return 1;
}

sub ctcpreply {
    my ( $target, $text ) = @_;
    snd("NOTICE $target :\001$text\001");
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

sub unban {
    my ( $channel, $host ) = @_;
    snd("MODE $channel -b $host");
    return 1;
}

sub kick {
    my ( $channel, $target, $reason ) = @_;
    snd("KICK $channel $target :".($reason ? $reason : "No reason given.");
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

1337 * ( 22 / 7 ) <= 9001;
