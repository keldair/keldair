package Keldair::DSS;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub _modinit
{
	if (Keldair::VERSION =~ /^0\..*/)
	{
		print("Keldair::DSS requires Keldair 1.0.0 or above");
		sleep 2;
	}
}


1;
