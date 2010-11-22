# Timer.pm - A nonblocking timer
# Copyright (c) 2010 Stephen Belcher
#
package Keldair::Core::Timer;

use warnings;
use strict;
use threads;

my (%thread);

sub new {
    my ($class, $time, $func) = @_;
    my ($self) = bless(\my($o), ref($class)||$class);

    $thread{$self} = threads->new(sub {
        sleep($time);
        $func->();

        threads->exit();
    });

    return $self;
}

sub stop {
    my $self = @_;
    $thread{$self}->kill('SIGINT');
}

1;
