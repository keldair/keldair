package Keldair::Quotes;

use strict;
use warnings;
use MongoDB;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair;

sub _modinit
{
	if (Keldair::VERSION !~ /^1\.0\.[123456789]/)
	{
		print("Keldair::Quotes requires Keldair 1.0.1 or above");
		sleep 2;
		no Keldair::Quotes;
	}
		
	our $conn = MongoDB::Connection->new(host => config('db/host'));
	our $db = $conn->config('db/name');
	our $quotes = $db->quotes;
}

sub command_addquote {
	my ( @parv, $channel, %user, $mtext ) = @_;
	my $quote = substr($mtext, length(config('cmdchar'))+8);
	$quotes->insert({"quote" => $quote, 
        "user" => $user->nick,
        "channel" => $channel });
}


1;
