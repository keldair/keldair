#!/usr/bin/env perl -wW

# Keldair.pm - Main module file for Keldair
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

package Keldair;

use strict;
use warnings;

sub snd {
    my ($text) = shift;
    chomp($text);
    print("SEND: $text\r\n");    #if $verbose;
    send( $main::sock, $text . "\r\n", 0 );
}

sub msg {
    my ( $target, $text ) = shift;
    snd( "PRIVMSG " . $target . " :" . $text );
}

sub notice {
    my ( $target, $text ) = shift;
    snd( "NOTICE " . $target . " :" . $text );
}

sub ctcp {
    my ( $target, $text ) = shift;
    snd( "PRIVMSG " . $target . " :\001" . $text . "\001" );
}

sub act {
    my ( $target, $text ) = shift;
    snd( "PRIVMSG " . $target . " :\001ACTION " . $text . "\001" );
}

sub oper {
    my ( $name, $pass ) = shift;
    snd( 'OPER ' . $name . ' ' . $pass );
}

sub kill {
    my ( $target, $msg ) = shift;
    snd("KILL $target :$msg");
}

sub config {
    my ( $block, $setting ) = shift;
    return $main::SETTINGS->{$block}->{$setting};
}

sub connect {
    my ( $ident, $gecos, $nick ) = @_;
    snd("USER $ident * * :$gecos");
    snd("NICK $nick");
}

sub ban {
	my ( $channel, $host ) = shift;
	snd("MODE $channel +b $host");
}

sub kick {
	my ( $channel, $nick, $reason ) = shift;
	snd("KICK $channel $nick :$reason");
}

1;
