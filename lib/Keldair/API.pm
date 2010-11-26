package Keldair::API;

use strict;
use warnings;
use Term::ANSIColor;

sub modinit { }

sub handle_notice {
    my ( $self, $origin, $target, $params, $line ) = @_;
    print("Origin: $origin->{origin}\nTarget: $target\nParams: $params\nLine: $line\n");
}

sub handle_authenticate {
    print color 'bold red';
    print("Oh hey, an AUTHENTICATE handle has been called!");
    print color 'reset';
}
sub handle_invite {
    my ( $self, $origin, $target, $params, $line ) = @_;
    print("Origin: $origin\nTarget: $target\nParams: $params\nLine: $line\n");
}


1;
