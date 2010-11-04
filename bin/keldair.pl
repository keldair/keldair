#!/usr/bin/env perl -w

# keldair.pl - Keldair core file
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

use strict;
use warnings;
use diagnostics;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use IO::Socket;
use File::Data;
use Config::JSON;
use Module::Load;
use Keldair qw(config);

my $rawlog = File::Data->new("$Bin/../var/raw.log");

Keldair->new("$Bin/../etc/keldair.conf");

my $fork = config("debug/fork");

if ( $fork =~ /^yes|y|1/i ) {
    open STDIN,  '/dev/null'   or die("Can't read /dev/null: $!");
    open STDOUT, '>>/dev/null' or die("Can't write to /dev/null: $!");
    open STDERR, '>>/dev/null' or die("Can't write to /dev/null: $!");
    my $pid = fork;

    unless ( $pid == 0 ) {
        writepid($pid);
        exit;
    }
}
