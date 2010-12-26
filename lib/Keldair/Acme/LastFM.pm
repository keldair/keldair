package Keldair::Acme::LastFM;

use Keldair qw(config msg);
use Net::LastFM;

our $lastfm = Net::LastFM->new(
	api_key    => config('lastfm/key'),
	api_secret => config('lastfm/secret'),
);

our $cmdchar = config('cmdchar');

sub modinit {
	print(__PACKAGE__." loaded\n");
	return 1;
}

sub handle_privmsg {
	my ( $origin, $target, $params, $line ) = @_;
	my @parv = split( ' ', $params );
	if ($params =~ /^$cmdchar(np|lastfm|nowplaying)/) {
		my $user = $parv[1];
		my $data = $lastfm->request_signed(
			method => 'user.getRecentTracks',
			user   => $user,
			limit  => 1
		);
		my $artist = $data->{recenttracks}->{track}->[0]->{artist}->{'#text'};
		my $song = $data->{recenttracks}->{track}->[0]->{name};
		msg($target, $origin->{nick}." is now playing: $artist - $song");
	}
	return 1;
}

1;
