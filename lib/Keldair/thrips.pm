package Keldair::thrips;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub handle_privmsg
{
    my ($hostmask, $channel, $mtext, undef) = @_;
        #if ($mtext =~ /^(k(\.|\.\..*)|well|.*technoirc.*|\.$|\.\..*|w(a|u)t)/i)
        #{
            #my ( undef, $to_ban ) = split('@', $hostmask);
            #ban($channel,"*!*\@$to_ban");
            #my ( $to_kick, undef) = split('!', $hostmask);
            #kick($channel, $to_kick, "tolerance for bullshit: gone");
        #}
        msg($channel, "$hostmask said $mtext in $channel");
}

1;
