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
use Config::Scoped;
use Module::Load;
use Keldair;

my $rawlog = File::Data->new("$Bin/../var/raw.log");

my $parser = Config::Scoped->new( file => "$Bin/../etc/keldair.conf", )
  or die("Cannot open config file!\n");

our $SETTINGS = $parser->parse;

our @modules = split( ' ', $SETTINGS->{'general'}->{'modules'} );

foreach my $mod (@modules) {
    load $mod;
    eval { $mod->_modinit; }
}

our $sock = IO::Socket::INET->new(
    Proto    => "tcp",
    PeerAddr => $SETTINGS->{'server'}->{'host'},
    PeerPort => $SETTINGS->{'server'}->{'port'},
) or die("Connection failed to $SETTINGS->{'server'}->{'host'}. \n");

if ( $SETTINGS->{'general'}->{'fork'} =~ /^yes|y|1/i ) {
    open STDIN,  '/dev/null'   or die("Can't read /dev/null: $!");
    open STDOUT, '>>/dev/null' or die("Can't write to /dev/null: $!");
    open STDERR, '>>/dev/null' or die("Can't write to /dev/null: $!");
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

Keldair::connect(
    $SETTINGS->{'keldair'}->{'ident'},
    $SETTINGS->{'keldair'}->{'real'},
    $SETTINGS->{'keldair'}->{'nick'}
);

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

    #print($command."\n");

    # Now, time for some commandish stuff!

    my $handler = 'handle_' . lc($command);

    foreach my $cmd (@modules) {
        eval { $cmd->$handler( $hostmask, $channel, $mtext, $line ); }

    }

    if ( $line =~ /^PING :/ ) {
        Keldair::snd( "PONG :" . substr( $line, index( $line, ":" ) + 1 ) );
    }
}
