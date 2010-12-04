package Keldair::Authen::UserServ;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(msg config);

sub modinit
{
    if (Keldair::VERSION =~ /^0\..*/)
    {
        print("Keldair::Authen::UserServ requires Keldair 1.0.0 or above");
        sleep 2;
    }
    my $self = shift;
    print("$self loaded\n");
}

sub handle_001
{
    msg(config("auth/service"), "LOGIN ".config("auth/user")." ".config("auth/pass"));
}

1;
