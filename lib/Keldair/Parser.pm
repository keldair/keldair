#!/usr/bin/env perl

# Parser.pm - Keldair::Parse IRC parsing
# Copyright 2010 Alexandria Wolcott <alyx@woomoo.org>
# Released under the 3 clause BSD license
# $Id$ $Revision$ $HeadURL$ $Date$ $Source$

package Keldair::Parser;

use strict;
use warnings;
use Carp qw(carp croak);
require Exporter;
use base "Exporter";
our @EXPORT_OK = qw(parse_irc);

our $VERSION = 1.1.0;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub parse {
    my ( $self, $raw ) = @_;
    if ( $raw =~ /(?:\:([^\s]+)\s)?(\w+)\s(?:([^\s\:]+)\s)?(?:\:?(.*))?$/xsm ) {
        my $event = {
            'raw '    => $raw,
            'origin'  => $1,
            'command' => $2,
            'target'  => $3,
            'params'  => $4,
        };
        if (defined($event->{origin})) {
            if ($event->{origin} =~ /(.*)!(.*)\@(.*)/xsm) {
                $event->{origin} = {
                    'raw' => $event->{origin},
                    'nick' => $1,
                    'user' => $2,
                    'host' => $3
                };
            }
        }
        return $event;
    }
    else {
        carp('Received non-IRC line!');
        return 0;
    }
}

sub parse_irc {
    my @args = @_;
    if ( defined( $args[1] ) ) {
        my $event = __PACKAGE__->parse( $args[1] );
        return $event;
    }
    else {
        my $event = __PACKAGE__->parse( $args[0] );
        return $event;
    }
}

1;
