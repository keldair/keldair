package Keldair::Numerics::001;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub _modinit
{
	if (Keldair::VERSION =~ /^0\..*/)
	{
		print("Keldair::Numerics::001 requires Keldair 1.0.0 or above");
		sleep 2;
	}
}

sub handle_001
{
    Keldair::snd("JOIN $main::SETTINGS->{'channels'}->{'debug'}");
    Keldair::snd("JOIN $main::SETTINGS->{'channels'}->{'general'}");
}

1;
