package Keldair::thrips;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub _modinit
{
	if (Keldair::VERSION =~ /^0\..*/)
	{
		print("Keldair::thrips requires Keldair 1.0.0 or above");
		sleep 2;
	}
}

sub handle_privmsg
{
    my ( $self, $hostmask, $channel, $mtext, $line) = @_;
        if ($mtext =~ /^(k(\.|\.\..*)|well|.*technoirc.*|\.$|\.\..*|w(a|u)t)/i)
        #if ($mtext =~ /^k .*/)
        {
            my ( undef, $to_ban ) = split('@', $hostmask);
            Keldair::ban($channel,"*!*\@$to_ban");
            my ( $to_kick, undef) = split('!', $hostmask);
            Keldair::kick($channel, $to_kick, "tolerance for bullshit: gone");
        }
        #Keldair::msg($channel, "in $channel $hostmask said $mtext");
		elsif ($mtext =~ /^k.?.?$/)
		{
			my ( undef, $to_ban ) = split('@', $hostmask);
            Keldair::ban($channel,"*!*\@$to_ban");
            my ( $to_kick, undef) = split('!', $hostmask);
            Keldair::kick($channel, $to_kick, "tolerance for bullshit: gone");
		}
	
}

1;
