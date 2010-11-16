package Keldair::API;

use strict;
use warnings;

sub _modinit { }

sub handle_notice {
    my ( $self, $origin, $target, $params, $line ) = @_;
    print("Origin: $origin\nTarget: $target\nParams: $params\nLine: $line\n");
}

1;
