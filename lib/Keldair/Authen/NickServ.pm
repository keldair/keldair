package Keldair::Authen::NickServ;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(msg config);

sub modinit
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
    msg("NickServ", "IDENTIFY ".config("auth/user")." ".config("auth/pass"));
}

1;
