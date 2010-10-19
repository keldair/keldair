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
	my $self = shift;
	print("$self loaded\n");
}

sub handle_001
{
    snd("PRIVMSG NickServ :IDENTIFY ".config("login/nsuser")." ".config("login/nspass"));
}

1;
