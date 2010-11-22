package Timer;

use warnings;
use strict;
use threads;
use Method::Signatures;

my (%thread);

method new($class: $time, $func) {
    my ($self) = bless(\my($o), ref($class)||$class);

    $thread{$self} = threads->new(sub {
        sleep($time);
        $func->();

        threads->exit();
    });

    return $self;
}

method stop() {
    $thread{$self}->kill('SIGINT');
}

if ($0 eq __FILE__) {
    Timer->new(3, sub { print "after 3 seconds!\n" });
    Timer->new(2, sub { print "after 2 seconds!\n" });

    sleep(5);
}

1;

__END__

$ perl test.pl
after 2 seconds!
after 3 seconds!
Perl exited with active threads:
        0 running and unjoined
        2 finished and unjoined
        0 running and detached
