#!/usr/bin/env perl -wW

# Keldair.pm - Main module file for Keldair
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

package Keldair;

use strict;
use warnings;
use diagnostics;
use Exporter 'import';
use Module::Load;
use constant {
    VERSIONSTRING => '1.0.1',
    VERSION       => 1,
    SUBVERSION    => 0,
    REVISION      => 1,
    RELEASESTAGE  => '',
    RELEASE       => ''
};

#load 'Keldair::Protocol::' . config('protocol');

# Note for future maintainers:
# VERSIONSTRING = Keldair::VERSION.'.'.Keldair::SUBVERSION.'.'.Keldair::REVISION.'-'.Keldair::RELEASESTAGE.Keldair::RELEASE;

@Keldair::EXPORT_OK =
  qw(act ban config ctcp kick kill mode msg notice oper snd);

# Remember to allow anything you want to call in modules.

sub snd {
    my ($text) = @_;
    chomp($text);
    print("SEND: $text\r\n") if config('debug/verbose') == 1;
    send( $main::sock, $text . "\r\n", 0 );
}

sub config {
    my ($value) = @_;
    my $setting = $main::SETTINGS->get($value);
    return $setting;
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

sub connect {
    my ( $ident, $gecos, $nick ) = @_;
    my $pass = config('server/pass');

	snd("PASS $pass") if defined($pass);
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
