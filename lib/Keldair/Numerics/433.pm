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
  my $newnick = $Keldair::me.'-';
  print "$Keldair::me is already in use.\n--> Concatenating to $newnick\n";
  snd "NICK $newnick";
  $Keldair::me = $newnick;
  return 1;
}

1;
