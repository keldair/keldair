package Keldair::Numerics::001;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(snd config);

sub modinit
{
	print(__PACKAGE__," loaded\n");
	return 1;
}

sub handle_001
{
	my $chans = config("channels/general");
	my $join = "JOIN ";
	foreach my $chan (@$chans) {
		$join .= $chan.',';
	}
    Keldair::snd("$join");
	return 1;
}

1;
