#!/usr/bin/env perl -wW

# Keldair.pm - Main module file for Keldair
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

package Keldair;

use strict;
use warnings;
use version;
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
		      SUBVERSION    => 2,
		      REVISION      => 1,
		      RELEASESTAGE  => q{},
		      RELEASE       => q{}
};

our $VERSION = '2.2.1';

# Note for future maintainers:
# VERSIONSTRING = Keldair::VERSION.'.'.Keldair::SUBVERSION.'.'.Keldair::REVISION.'-'.Keldair::RELEASESTAGE.Keldair::RELEASE;

@Keldair::EXPORT_OK =
qw(act away back ban cjoin config connect ctcp kick mode modlist modload msg notice oper snd topic userkill cpart);

our ( @modules, $sock, $SETTINGS, $me );

# Remember to allow anything you want to call in modules.

sub new {
	my $self = shift;
	my ($config) = $_[0];
	$SETTINGS = Config::JSON->new($config)
		or die("Cannot open config file!\n");
	my $modref = $SETTINGS->get('modules');
	my @tmp    = @$modref;
	foreach my $mod (@tmp) {
		Keldair::modload($mod);
	}
	push( @modules, 'main' );
	foreach my $mod (@modules) {
		eval { $mod->on_startup; 1; };
	}
	_connect( config('server/host'), config('server/port') ) or
		croak("Error connecting to server: $!\n");
	return 1;
}

sub _loop {
	my ($line);
	while ( $line = <$sock> ) {
		my $verbose = config('debug/verbose');
		$verbose ||= 'no';
		print ">> ".$line if $verbose =~ (m/^(y.*|on|1|t.*)$/ix);
		$line =~ s/\r\n//x;

		my $event = parse_irc($line);

		my $handler = 'handle_' . lc( $event->{command} );

		foreach my $cmd (@modules) {
			eval {
				$cmd->$handler(
						$event->{origin}, $event->{target},
						$event->{params}, $line
					      );
				1;
			};
		}

		if ( $event->{command} eq '001' ) {
			foreach my $cmd (@modules) {
				eval { $cmd->on_connect; 1; };
			}
		}

		if ( $event->{command} eq 'PRIVMSG' ) {
			my @args = split(' ', $event->{params});
			if ($line =~ m/\001/x) { # This is a ctcp
				$event->{params} =~ s/\001//gx;
				my ($ctcp, undef) = split(' ', $event->{params});
				$handler = 'ctcp_'.lc($ctcp);
				foreach my $cmd (@modules) {
					eval {
						$cmd->$handler($event, $line);
						1;
					}
				}
			}
			if (substr($args[0], 0, 1) eq config('cmdchar')) {
				$handler = 'cmd_'.lc($event->{command});
				foreach my $cmd (@modules) {
					eval {
						$cmd->$handler($event->{origin}, $event->{target}, $event->{params}, $line);
						1;
					};
				}
			}
		}

		elsif ( $event->{command} eq 'PING') {
#snd( "PONG :" . substr( $line, index( $line, ":" ) + 1 ) );
			snd( "PONG :$event->{params}" );
		}

	}
	foreach my $cmd (@modules) {
		eval { $cmd->on_disconnect; 1; };
	}
	return 1;
}

sub _connect {
#$sock = Keldair::Core::Connect->init() or croak("Connection failed: $!");

	my %connecthash = (
			'Proto'    => "tcp",
			'PeerAddr' => Keldair::config('server/host'),
			'PeerPort' => Keldair::config('server/port'),
			'Timeout'  => 30
			);

	if ( config('server/ssl') =~ /^(y.*|on|1|t.*)$/ix ) {
		eval { require IO::Socket::SSL; } or croak("Missing IO::Socket::SSL");

#if ( config( 'ssl/certfp' =~ /^(y.*|on|1|t.*)$/i ) ) {
#$connecthash{'SSL_cert_file'} = config('ssl/certfp/filename');
#if ( config('ssl/certfp/passwd') ) {
#$connecthash{'SSL_passwd_cb'} =
#sub { return config('ssl/certfp/passwd'); }
#}
#}
		$sock = IO::Socket::SSL->new(%connecthash)
			or
			croak( "Connection failed to " . config('server/host') . ": $!\n" );
	}

	else {
		$sock = IO::Socket::INET->new(%connecthash)
			or
			croak( "Connection failed to " . config('server/host') . ": $!\n" );
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
	$me = $nick;
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

# eval { $mod->modinit; } or cluck("Missing modinit!")      and return 0;
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
	my $verbose = config('debug/verbose');
	$verbose ||= 'no';
	if ($verbose =~ /^(y.*|on|1|t.*)$/i)
	{
		print("<< $text\r\n");
	}
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
	snd( "PRIVMSG $target :\001ACTION $text\001" );
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
	snd("KICK $channel $target :".($reason ? $reason : "No reason given."));
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
	snd('AWAY');
	return 1;
}

sub cjoin {
	my ($channel) = @_;
	snd("JOIN $channel");
	return 1;
}

sub cpart {
	my ($channel,$reason) = @_;
	snd("PART $channel :".$reason);
	return 1;
}

sub nick {
	my $nick = @_;
	snd("NICK $nick");
	return $nick;
}


1337 * ( 22 / 7 ) <= 9001;
