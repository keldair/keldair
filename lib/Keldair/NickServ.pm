package Keldair::NickServ;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub handle_001
{
    Keldair::snd("PRIVMSG NickServ :IDENTIFY $main::SETTINGS->{'keldair'}->{'nspass'}");
}

1;
