package Keldair::Numerics::001;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub handle_001
{
    Keldair::snd("JOIN $main::SETTINGS->{'channels'}->{'debug'}");
}

1;
