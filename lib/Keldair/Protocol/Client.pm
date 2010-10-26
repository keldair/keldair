#!/usr/bin/env perl -wW

package Keldair::Protocol::Client;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(snd);

@Keldair::Protocol::Client::EXPORT =
  qw(act ban connect ctcp kick kill mode msg notice oper);

sub msg {
    my ( $target, $text ) = @_;
    snd( "PRIVMSG " . $target . " :" . $text );
}

sub notice {
    my ( $target, $text ) = @_;
    snd( "NOTICE " . $target . " :" . $text );
}

sub ctcp {
    my ( $target, $text ) = @_;
    snd( "PRIVMSG " . $target . " :\001" . $text . "\001" );
}

sub act {
    my ( $target, $text ) = @_;
    snd( "PRIVMSG " . $target . " :\001ACTION " . $text . "\001" );
}

sub oper {
    my ( $name, $pass ) = @_;
    snd( 'OPER ' . $name . ' ' . $pass );
}

sub kill {
    my ( $target, $msg ) = @_;
    snd("KILL $target :$msg");
}

sub connect {
    my ( $ident, $gecos, $nick ) = @_;

    #snd("CAP LS");
    snd("USER $ident * * :$gecos");
    snd("NICK $nick");
}

sub ban {
    my ( $channel, $host ) = @_;
    snd("MODE $channel +b $host");
}

sub kick {
    my ( $channel, $nick, $reason ) = @_;
    snd("KICK $channel $nick :$reason");
}

sub mode {
    my ( $target, $modes ) = @_;
    snd("MODE $target $modes");
}

1;
