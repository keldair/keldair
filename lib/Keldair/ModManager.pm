package Keldair::ModManager;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Module::Load;
use Keldair;

sub handle_privmsg
{
	my ($host,$channel,$text,undef) = shift;
	my ($nick,undef) = split('!', $host);
	if (lc($nick) eq lc($main::SETTINGS->{'general'}->{'admin'}))
	{
		#my (@words) = split(/ /,$text);
		if ($text =~ /^modload/i)
		{
			my $query = substr($text, 8);
			eval { load $query; };
			if (@_)
			{
				Keldair::msg($channel,@_);
			}
			else
			{
				Keldair::msg($channel,"Module $query loaded.");
			}
		}
	}
}

1;
