package Keldair::Acme::Ubuntu;

use strict;
use warnings;
use Switch;
use Keldair qw(msg part nick cjoin);

sub modinit { }

sub handle_notice {
    my ( $self, $origin, $target, $params, $line ) = @_;
    print(
"Origin: $origin->{origin}\nTarget: $target\nParams: $params\nLine: $line\n"
    );
}

sub handle_privmsg {
    my ( $self, $origin, $target, $params, $line ) = @_;
    switch ($params) {
        case 'What is the letter between M and O alphabetically?' {
            msg( $target, 'N' )
        }
        case 'How many legs does a human have?'   { msg( $target, '2' ) }
        case 'How many hours are there in a day?' { msg( $target, '24' ) }
        case 'What is the last letter of the English alphabet?' {
            msg( $target, 'z' )
        }
        case m/^Type the word '(.*)' .*/i { msg( $target, $1 ) }
        case 'What is the last month of the year?' {
            msg( $target, 'December' )
        }
        case 'Type the number 1 in letters, not in digits' {
            msg( $target, 'one' )
        }
        case 'What day comes before Saturday?' { msg( $target, 'Friday' ) }
        case 'Type the number 6 in letters, not in digits' {
            msg( $target, 'six' )
        }
        case 'Is Ubuntu the best free operating system in the world?' {
            msg( $target, 'yes' )
        }    #Not in the slightest, but say yes to appease stupid Ubuntards.
        case 'What is the letter between S and U in the alphabet?' {
            msg( $target, 'T' )
        }
        case /^What (is the letter between (.*) and (.*) in the alphabet|letter is between (.*) and (.*) (alphabetically|in the Latin alphabet))\?/i {
            msg($target, chr(ord($1)+1))
        }
        case m/^How many letters are there in the word '(.*)' .*/i {
            msg( $target, length($1) )
        }
        case 'How many seconds are there in a minute?' { msg( $target, '60' ) }
        case 'What is the last name of Linus Torvalds (the creator of Linux)?' {
            msg( $target, 'Torvalds' )
        }
        case /^What color is a (.*) (.*)/i { msg( $target, $1 ) }
        case
'How much wood would a woodchuck chuck, if a woodchuck could chuck wood?'
        {
            bail( $target, $params )
        }
        case 'What letter is between A and C alphabetically?' { }

    }
}

sub bail {
    my ( $channel, $params ) = @_;
    carp(   "The authors of "
          . __PACKAGE__
          . " don't know the answer to:\n$params\nIf you know the answer, contact us in #dev on irc.woomoo.org\n"
    );
    my $newnick = config('keldair/nick');
    my $newnick =~ tr[a-zA-Z][n-za-mN-ZA-M];
    part($channel);
    sleep 2;
    nick($newnick);
    sleep 2;
    cjoin($channel);
    return $newnick;
}

sub splitword {
    my ($params) = @_;
    if ($params =~ /^What is the first letter in the word '(.*)'\?/) {
        my @chars = split('', $1);
        return $chars[0];
    }
    elsif ($params =~ /^What is the last letter in the word '(.*)'\?/) {
        my $word = $1;
        my @chars = split('', $word);
        return $chars[length($word)-1];
    }
}

#What is the first letter in the word 'Gentoo'?
#What is the last letter in the word 'Macintosh'?

sub handle_invite {
    my ( $self, $origin, $target, $params, $line ) = @_;
    print("Origin: $origin\nTarget: $target\nParams: $params\nLine: $line\n");
}

1;
