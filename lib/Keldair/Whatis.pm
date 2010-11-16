package Keldair::Whatis;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(snd msg);

sub _modinit
{
    if (Keldair::VERSION =~ /^0\..*/)
    {
        print("Keldair::Whatis requires Keldair 1.0.0 or above");
        sleep 2;
    }
    my $self = shift;
    print("$self loaded\n");
}

sub command_whatis {
    my ( $self, @parv, $channel, %user, $mtext ) = @_;
    my $whatis = system("whatis $parv[1]");
    if ($whatis =~ /.*\n.*/) {
        my @what = split(/\n/, $whatis);
        msg($channel, $what[0]);
    }
    else {
        msg($channel, $whatis);
    }
}

1;
