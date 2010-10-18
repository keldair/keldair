package Keldair::NickServ;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub _modinit
{
	if (Keldair::VERSION =~ /^0\..*/)
	{
		print("Keldair::NickServ requires Keldair 1.0.0 or above");
		sleep 2;
	}
}

sub handle_001
{
    Keldair::snd("PRIVMSG NickServ :IDENTIFY $main::SETTINGS->{'keldair'}->{'nspass'}");
}

1;
