#!/usr/bin/local/perl
use Timer;

my $time = Keldair::Core::Timer->new();

$time->run(5, 'print "Dicks\n"');
sleep 10;
