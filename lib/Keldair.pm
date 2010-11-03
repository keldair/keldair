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
use Module::Load;
use constant {
    VERSIONSTRING => '2.0.0-alpha1',
    VERSION       => 2,
    SUBVERSION    => 0,
    REVISION      => 0,
    RELEASESTAGE  => 'alpha',
    RELEASE       => '1'
};

# Note for future maintainers:
# VERSIONSTRING = Keldair::VERSION.'.'.Keldair::SUBVERSION.'.'.Keldair::REVISION.'-'.Keldair::RELEASESTAGE.Keldair::RELEASE;

@Keldair::EXPORT_OK =
  qw(act ban config ctcp kick kill mode msg notice oper snd);

our (@modules,$sock);

# Remember to allow anything you want to call in modules.


sub connect {
	my $self = shift;
	my ( $host, $port ) = @_;
	if ($self->config('server/ssl' =~ /^y.*/) {
	require IO::Socket::SSL;
	$sock = IO::Socket::SSL->new(
		Proto	 => "tcp",
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
$self->_connect($self->config('keldair/user'), $self->config('keldair/real'), $self->config('keldair/nick') );
$self->_loop;
}

sub _connect {
    my ( $ident, $gecos, $nick ) = @_;
    my $pass = config('server/pass');

	snd("PASS $pass") if defined($pass);
    snd("USER $ident * * :$gecos");
    snd("NICK $nick");
}

#---------------------------------------------
# Below here, only the API commands are shown.
#---------------------------------------------

sub modload {
	my ($module) = @_;
	load $module;
	push (@modules, $module);
}

sub modunload {
	my ($module) = @_;
	no $module;
	@modules = grep{!/^$module$/}
}

#------------------------
# IRC commands only here.
#------------------------

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
