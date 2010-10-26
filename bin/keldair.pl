#!/usr/bin/env perl -w

# keldair.pl - Keldair core file
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use IO::Socket;
use File::Data;
use Config::JSON;
use Module::Load;
use Keldair qw(config);

my $rawlog = File::Data->new("$Bin/../var/raw.log");

our $SETTINGS = Config::JSON->new("$Bin/../etc/keldair.conf")
  or die("Cannot open config file!\n");

my $modref = $SETTINGS->get("modules");

our @modules = @$modref;

foreach my $mod (@modules) {
    load $mod;
    eval { $mod->_modinit; };
}

my $host = $SETTINGS->get("server/host");
my $port = $SETTINGS->get("server/port");

our $sock = IO::Socket::INET->new(
    Proto    => "tcp",
    PeerAddr => $host,
    PeerPort => $port,
) or die("Connection failed to $host. \n");

my $fork = $SETTINGS->get("fork");

if ( $fork =~ /^yes|y|1/i ) {
    open STDIN,  '/dev/null'   or die("Can't read /dev/null: $!");
    open STDOUT, '>>/dev/null' or die("Can't write to /dev/null: $!");
    open STDERR, '>>'.$Bin.'../var/error.log' or die("Can't write to $Bin/../var/error.log: $!");
    my $pid = fork;

    unless ( $pid == 0 ) {
        writepid($pid);
        exit;
    }
}
my (
    $line,    $nickname,  $command,    $mtext, $hostmask,
    $channel, $firstword, @spacesplit, @words
);

my ( $user, $real, $nick ) = (
    $SETTINGS->get("keldair/user"),
    $SETTINGS->get("keldair/real"),
    $SETTINGS->get("keldair/nick")
);

Keldair::connect( $user, $real, $nick );

# Ok, I do believe connecting is important, eh? :P

IRC: while ( $line = <$sock> ) {

# First, since this is a loop, we undefine all the special and REALLY IMPORTANT variables!
    undef $nickname;
    undef $command;
    undef $mtext;
    undef $hostmask;

    # Mkay, now let's kill off those \r\n's at the end of $line.
    chomp($line);
    chomp($line);

    # Hey, let's print the line too!
    print( $line. "\r\n" );

    # Hell, why not? Let's log it too, for teh lulz!
    #$rawlog->append(time." ".$line."\n");

    # Now, time to /extract/ those there variables!
    $hostmask = substr( $line, index( $line, ":" ) );
    $mtext = substr( $line, index( $line, ":", index( $line, ":" ) + 1 ) + 1 );
    ( $hostmask, $command ) =
      split( " ", substr( $line, index( $line, ":" ) + 1 ) );
    ( $nickname, undef ) = split( "!", $hostmask );
    @spacesplit = split( " ", $line );
    $channel = $spacesplit[2];

    # Now, time for some commandish stuff!

    my $handler = 'handle_' . lc($command);

    foreach my $cmd (@modules) {
        eval { $cmd->$handler( $hostmask, $channel, $mtext, $line ); };
    }
    
    if ($command eq 'PRIVMSG') {
		my $cmdchar = config('cmdchar');
		if ($mtext =~ /^$cmdchar/) {
			my $text = substr($mtext, length($cmdchar));
			my @parv = split(' ', $text);
			my $handler = 'command_' . lc($parv[0]);
			my (%user, $garbage);
			($user{'nick'}, $garbage) = split('!', $hostmask);
			($user{'ident'},$user{'host'}) = split('@', $garbage);
			foreach my $cmd (@modules) {
				eval { $cmd->$handler( @parv, $channel, %user, $mtext ); };
			}
		}
	}

    if ( $line =~ /^PING :/ ) {
        Keldair::snd( "PONG :" . substr( $line, index( $line, ":" ) + 1 ) );
    }
}
