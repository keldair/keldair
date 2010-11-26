# Copyright (c) 2010 Samuel Hoffman
package Keldair::Numerics::433;
use strict;
use warnings;
use Keldair qw(snd config);
use FindBin qw($Bin);
use lib "$Bin/../lib";

sub modinit
{
  print __PACKAGE__." loaded.\n";
  return 1;
}

sub handle_433
{
  my $nick = config('keldair/nick');
  print "$nick is already in use.\n--> Concatenating to $nick-\n";
  snd "NICK $nick-";
  return 1;
}

1;
