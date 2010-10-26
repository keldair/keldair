#!/usr/bin/env perl -wW

# Keldair.pm - Main module file for Keldair
# Copyright 2010 Chazz Wolcott <chazz@staticbox.net>
# Released under the BSD Public License

package Keldair;

use strict;
use warnings;
use Exporter 'import';
use Module::Load;
use constant {
    VERSIONSTRING => '1.0.1-alpha1',
    VERSION       => 1,
    SUBVERSION    => 0,
    REVISION      => 1,
    RELEASESTAGE  => 'alpha',
    RELEASE       => 1
};

load 'Keldair::Protocol::' . config('protocol');

# Note for future maintainers:
# VERSIONSTRING = Keldair::VERSION.'.'.Keldair::SUBVERSION.'.'.Keldair::REVISION.'-'.Keldair::RELEASESTAGE.Keldair::RELEASE;

@Keldair::EXPORT_OK =
  qw(act ban config ctcp kick kill mode msg notice oper snd);

# Remember to allow anything you want to call in modules.

sub snd {
    my ($text) = @_;
    chomp($text);
    print("SEND: $text\r\n");    #if $verbose;
    send( $main::sock, $text . "\r\n", 0 );
}

sub config {
    my ($value) = @_;
    my $setting = $main::SETTINGS->get($value);
    return $setting;
}

1;
