#!/usr/bin/env perl -wW

# Keldair.pm - Main module file for Keldair
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

package Keldair;

use strict;
use warnings;
use Exporter 'import'; 
use constant {
	VERSION => '1.0.0-alpha3'
};

@Keldair::EXPORT_OK = qw(act ban config ctcp kick kill msg notice oper snd);

sub snd {
    my ($text) = @_;
    chomp($text);
    print("SEND: $text\r\n");    #if $verbose;
    send( $main::sock, $text . "\r\n", 0 );
}

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

sub config {
    my ( $value ) = @_;
    my $setting = $main::SETTINGS->get($value);
    return $setting;
}

sub connect {
    my ( $ident, $gecos, $nick ) = @_;
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

1;
