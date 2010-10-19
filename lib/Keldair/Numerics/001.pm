package Keldair::Numerics::001;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(snd);

sub _modinit
{
	if (Keldair::VERSION =~ /^0\..*/)
	{
		print("Keldair::Numerics::001 requires Keldair 1.0.0 or above");
		sleep 2;
	}
	my $self = shift;
	print("$self loaded\n");
}

sub handle_001
{
	my $chans = config("channels/general");
	my $join = "JOIN ";
	foreach my $chan (@$chans) {
		$join .= $chan;
	}
    Keldair::snd("$join");
}

1;
