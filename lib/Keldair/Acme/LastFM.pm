package Keldair::Acme::LastFM;

use Keldair qw(config msg);
use Net::LastFM;

our $lastfm = Net::LastFM->new(
    api_key    => config('lastfm/key'),
    api_secret => config('lastfm/secret'),
);

sub modinit {
    print(__PACKAGE__." loaded\n");
    return 1;
}

*cmd_np      = \*cmd_lastfm;
*cmd_playing = \*cmd_lastfm;

sub cmd_lastfm {
    my ( $origin, $target, $params, $line ) = @_;
    my @parv = split( ' ', $params );
    my $user = $parv[1];
    my $data = $lastfm->request_signed(
        method => 'user.getRecentTracks',
        user   => $user,
        limit  => 1
    );
    my $artist = $data->{recenttracks}->{track}->[0]->{artist}->{'#text'};
    my $song = $data->{recenttracks}->{track}->[0]->{name};
    msg($target, $origin->{nick}." is now playing: $artist - $song");
    return 1;
}

1;
