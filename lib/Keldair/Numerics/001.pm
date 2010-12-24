package Keldair::Numerics::001;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(cjoin config);

sub modinit
{
	print(__PACKAGE__," loaded\n");
	return 1;
}

sub handle_001
{
	my $chans = config("channels/general");
  print "Connected to IRC!\nJoining channels: @$chans\n";
	my $c;
	foreach (@$chans) {
		$c .= $_.',';
	}
        Keldair::cjoin($c);
	return 1;
}

1;
