package Keldair::SASL;

use strict;
use warnings;
use MIME::Base64;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Keldair qw(snd config);

sub _modinit
{
	if (Keldair::VERSION =~ /^0\..*/)
	{
		print("Keldair::SASL requires Keldair 1.0.0 or above");
		sleep 2;
	}
}

sub handle_cap
{
    my ( $self, $hostmask, $channel, $mtext, $line) = @_;
	my $tosend = '';
	if ($line =~ / LS /) {
		if ($line =~ /multi-prefix/i) {
			$tosend .= ' multi-prefix';
		}
		if ($line =~ /sasl/i) {
			$tosend .= ' sasl';
		}
		$tosend =~ s/^ //;
		if ($tosend eq '') {
			snd('CAP END');
		}
		else {
			snd("CAP REQ :$tosend");
		}
	}
	elsif ($line =~ / ACK /) {
		if ($mtext =~ /sasl/i) {
			snd('AUTHENTICATE PLAIN');
		}
	}
	elsif ($line =~ / NAK /) {
		snd('CAP END');
	}
}

sub handle_authenticate {
	my $u = config('login/nsuser');
	my $p = config('login/nspass');
	my $out = join("\0", $u, $u, $p);
	$out = encode_base64($out, "");
	
	if (length $out == 0) {
		snd("AUTHENTICATE +");
		return;
	}
	else {
		while (length $out >= 400) {
			my $subout = substr($out, 0, 400, '');
			snd("AUTHENTICATE $subout");
		}
		if (length $out) {
			snd("AUTHENTICATE $out");
		}
		else {
			snd("AUTHENTICATE +");
		}
	}
}

sub handle_903 {
	print("SASL authentication successful\n");
	snd('CAP END');
}

sub handle_904 {
	print("SASL authentication failed\n");
	snd('CAP END');
}

1;
